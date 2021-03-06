#/bin/ash
set -x

# Recive command lines arguments as files, the first is the data to post, the second is the comparation
out=''
post="$1"
comp="$2"
port=8080
addr=ng

# Wait for connection
curl --retry-delay 6 --connect-timeout 5 --max-time 5 --retry 5\
                --retry-connrefused --silent --fail ${addr}:

# set default  test files in case of no command line arguments
[ -z $post ] && post=e2e-in.txt
[ -z $comp ] && comp=e2e-comp.txt

# Reads post data file line by line and save the response to var
while IFS= read -r line <&3 || [ -n "$line" ]; do
  out=$out`curl --silent prod:9191/api/search?q=$line | jq .[].author`
  out="$out
"
done 3< "$post"

# Trim all white spaces
out=`printf "$out" | xargs`
comp=`cat $comp | xargs`

# Compare to response with the provided expected outcome
if [ "$out" = "$comp" ]; then
    printf "E2E tests are done\n"
else
    printf "E2E tests failed\n"
    exit 1
fi

# Parameter expansions not working in busybox
#"${post='test-in.txt'}"
#"${comp='t-comp.txt'}"
