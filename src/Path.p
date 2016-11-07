###############################################################################
# $ID: Path.p, 7 Nov 2016 20:44, Leonid 'n3o' Knyazev $
###############################################################################
@CLASS
Als/Path


@OPTIONS
locals
static



###############################################################################
@auto[]
# @{string} [separator]
$self.separator[/]

# @{string} [delimiter]
$self.delimiter[:]

# @{string} [cwd]
$self.cwd[${self.separator}^env:DOCUMENT_ROOT.trim[both;$self.separator]]
#end @auto[]



###############################################################################
@resolve[*paths]
$result[]

$paths[^hash::create[$paths]]
$count(^paths.count[] - 1)

$isAbsolute(false)

^if($count >= 0){
	^while($count >= 0){
		$path[^paths.at($count)[value]]
		$path[^path.trim[]]

		^self._assert[$path]

		^if(^path.length[] == 0){
			^count.dec[]
			^continue[]
		}

		$result[${path}^if(def $result){${self.separator}${result}}]

		$isAbsolute(^self.isAbsolute[$path])

		^if($isAbsolute){
			^break[]
		}{
			^count.dec[]
		}
	}

	$result[^self._normalize[$result;!$isAbsolute]]

	^if($isAbsolute){
		^if(^result.length[] > 0){
			$result[${self.separator}${result}]
		}{
			$result[$self.separator]
		}
	}(^result.length[] > 0){
		$result[${self.cwd}${self.separator}${result}]
	}{
		$result[$self.cwd]
	}
}{
	$result[$self.cwd]
}
#end @resolve[]


###############################################################################
@normalize[path]
$result[]

^self._assert[$path]

^if(^path.length[] > 0){
	$isAbsolute(^path.left(1) eq $self.separator)
	$trailingSeparator(^path.right(1) eq $self.separator)

	$path[^self._normalize[$path;$isAbsolute]]

	^if(^path.length[] == 0 && !$isAbsolute){
		$path[.]
	}

	^if(^path.length[] > 0 && $trailingSeparator){
		$path[${path}${self.separator}]
	}

	^if($isAbsolute){
		$path[${self.separator}${path}]
	}

	$result[$path]
}{
	$result[.]
}
#end @normalize[]


###############################################################################
@join[*paths]
$result[]

$paths[^hash::create[$paths]]

^if(^paths.count[] > 0){
	^paths.foreach[_index;_path]{
		$path[^_path.trim[]]

		^self._assert[$path]

		^if(def $path){
			$result[^if(def $result){${result}${self.separator}}${path}]
		}
	}

	^if(!def $result){
		$result[.]
	}{
		$result[^self.normalize[$result]]
	}
}{
	$result[.]
}
#end @join[]


###############################################################################
@relative[from;to]
$result[]

^self._assert[$from]
^self._assert[$to]

^if($from ne $to){
	$from[^self.resolve[$from]]
	$to[^self.resolve[$to]]

	^if($from ne $to){
		^for[fromStart](1;^from.length[]){
			^if(^from.mid($fromStart;1) ne $self.separator){
				^break[]
			}
		}
		$fromEnd(^from.length[])
		$fromLen($fromEnd - $fromStart)


		^for[toStart](1;^to.length[]){
			^if(^to.mid($toStart;1) ne $self.separator){
				^break[]
			}
		}
		$toEnd(^to.length[])
		$toLen($toEnd - $toStart)


		$length(^if($fromLen < $toLen){$fromLen}{$toLen})
		$lastCommonSep(-1)

		^for[i](0;$length){
			^if($i == $length){
				^if($toLen > $length){
					^if(^to.mid(($toStart + $i);1) eq $self.separator){
						$result[^to.mid(($toStart + $i + 1);^to.length[])]
					}($i == 0){
						$result[^to.mid(($toStart + $i);^to.length[])]
					}
				}($fromLen > $length){
					^if(^from.mid(($fromStart + $i);1) eq $self.separator){
						$lastCommonSep($i)
					}($i == 0){
						$lastCommonSep(0)
					}
				}

				^break[]
			}

			$fromCode[^from.mid(($fromStart + $i);1)]
			$toCode[^to.mid(($toStart + $i);1)]

			^if($fromCode ne $toCode){
				^break[]
			}($fromCode eq $self.separator){
				$lastCommonSep($i)
			}
		}

		^if(!def $result){
			$return[]
			$index($fromStart + $lastCommonSep + 1)

			^while($index <= $fromEnd){
				^if($index == $fromEnd || ^from.mid($index;1) eq $self.separator){
					^if(^return.length[] == 0){
						$return[..]
					}{
						$return[${return}/..]
					}
				}

				^index.inc[]
			}


			^if(^return.length[] > 0){
				$result[${return}^to.mid(($toStart + $lastCommonSep);^to.length[])]
			}{
				^toStart.inc($lastCommonSep)

				^if(^to.mid($toStart;1) eq $self.separator){
					^toStart.inc[]
				}

				$result[^to.mid($toStart;^to.length[])]
			}
		}
	}
}
#end @relative[]


###############################################################################
@dirname[path]
$result[]

^self._assert[$path]

^if(def $path){
	$result[^file:dirname[$path]]
}{
	$result[.]
}
#end @dirname[]


###############################################################################
@basename[path;ext]
$result[]

^if(def $ext && !($ext is string)){
	^throw[invalid.argument;$self.CLASS_NAME;'ext' argument must be a string. Received: $ext.CLASS_NAME]
}

^self._assert[$path]

^if(def $path){
	$result[^file:basename[$path]]

	^if(def $ext && $ext eq ^self.extname[$path]){
		$result[^file:justname[$path]]
	}
}
#end @basename[]


###############################################################################
@extname[path]
$result[]

^self._assert[$path]

^if(def $path){
	$result[^file:justext[$path]]

	^if(def $result){
		$result[.${result}]
	}
}
#end @extname[]


###############################################################################
@format[hPath]
^if(!def $hPath || !($hPath is hash)){
	^throw[invalid.argument;$self.CLASS_NAME;Parameter "hPath" must be an object, not $hPath.CLASS_NAME]
}

$result[^self._format[/;$hPath]]
#end @format[]


###############################################################################
@parse[path]
$result[^hash::create[
	$.root[]
	$.dir[]
	$.base[]
	$.ext[]
	$.name[]
]]

^if(def $path){
	^if(^self.isAbsolute[$path]){
		$result.root[$self.separator]
	}

	$result.dir[^self.dirname[$path]]
	$result.base[^self.basename[$path]]
	$result.ext[^self.extname[$path]]
	$result.name[^self.basename[$path;$result.ext]]
}
#end @parse[]


###############################################################################
@isAbsolute[path]
$result(false)

^self._assert[$path]

^if(def $path && ^path.left(1) eq $self.separator){
	$result(true)
}
#end @isAbsolute[]



###############################################################################
###############################################################################
@_assert[path]
^if(!($path is string)){
	^throw[invalid.argument;$self.CLASS_NAME;Path must be a string. Received: $path.CLASS_NAME]
}
#end @_assert[]


###############################################################################
@_format[separator;hPath]
$dir[^if(def $hPath.dir){$hPath.dir}{$hPath.root}]
$base[^if(def $hPath.base){$hPath.base}{${hPath.name}${hPath.ext}}]

$result[]

^if(!def $dir){
	$result[$base]
}($dir eq $hPath.root){
	$result[${dir}${base}]
}{
	$result[${dir}${separator}${base}]
}
#end @_format[]


###############################################################################
@_normalize[path;isAbsolute]
$result[]

$isAbsolute(^isAbsolute.bool(^path.left(1) eq $self.separator))

$path[^path.trim[both;$self.separator]]

$parts[^path.split[$self.separator;l]]
$parts[^parts.select(def ^parts.piece.trim[] && ^parts.piece.trim[] ne ".")]

$paths[^table::create{path}]

^parts.menu{
	$part[^parts.piece.trim[]]

	^if($part eq '..'){
		^if($isAbsolute){
			^if(^paths.count[]){
				^paths.delete[]
			}
		}{
			^if(^paths.count[]){
				^if($paths.path eq '..'){
					^paths.append{$part}
				}{
					^paths.delete[]
				}
			}{
				^paths.append{$part}
			}
		}
	}{
		^paths.append{$part}
	}

	^paths.offset[set]($paths - 1)
}

$result[^paths.menu{$paths.path}[$self.separator]]
#end @_normalize[]
