## Test contract
install packages
`npm install`

test the contract
`npx hardhat test`


## To deploy on local network
run local node on a terminal
`npx hardhat node`

deploy contract v1
`npx hardhat run --network localhost scripts/deploy.js`

deploy contract v2
`npx hardhat run --network localhost scripts/2_deploy.js`