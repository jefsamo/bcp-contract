import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

const BASE_SEPOLIA_URL = process.env.BASE_SEPOLIA_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

const config: HardhatUserConfig = {
  solidity: "0.8.27",
  networks: {
    baseSepolia: {
      url: BASE_SEPOLIA_URL,
      accounts: PRIVATE_KEY !== "" ? [PRIVATE_KEY] : [],
    },
  },
};

export default config;
