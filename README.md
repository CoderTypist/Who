# Who

## WhoHog

### Description
Find how many bytes and gb are being used by each directory inside of the current working directory. Also get the percentage of file system storage being used by each directory

### Usage
`./whohog.sh <file_system_mount_location>`

### Motivation
I was given access to a shared server to do hw, but the file system ran out of space. I wanted to know _who_ was _hogging_ all of the space.

## who

### Description
Uses the `w` command to see who is logged on while omitting unecessary details that may violate user privacy. In order to be effective, an alias for `w` should be added to the `.bashrc` file that invokes the `who` script.

### Usage
`w` or `who` (who can be called directly if placed in a directory on PATH)

### Motivation
`w`, although helpful for determining whether or not to shut down a server (e.g., you don't want to shut off a server while there are active users), it yields too much information. `who` strips off this information and only leaves the relevant details.
