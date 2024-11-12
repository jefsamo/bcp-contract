import { ethers } from "hardhat";

async function main() {
  // Get the deployer's account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy the Voting contract
  const Voting = await ethers.getContractFactory("Voting");
  const voting = await Voting.deploy();
  await voting.getDeployedCode();
  const address = await voting.getAddress();

  console.log("Voting contract deployed to:", address);
}

const deployContract = async () => {
  try {
    await main();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};
deployContract();
