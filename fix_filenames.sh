MOD_DIR="$HOME/.factorio/mods"
CWD=`pwd`

# Requires jq, the command line json parser
if ! type jq &> /dev/null; then
	echo Please install jq
	exit
fi

for mod in "$CWD"/*/; do
	# if github repo, change name to include correct title and version
	if [ -f $mod/info.json ]; then
			name=`jq .name $mod/info.json | tr -d '"'`
			version=`jq .version $mod/info.json | tr -d '"'`
			link="$MOD_DIR"/"$name"_"$version"
			ln -s $mod $link
	fi
done
