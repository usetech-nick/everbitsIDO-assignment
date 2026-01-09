import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying with:", deployer.address);

    const UNISWAP_V2_ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
    const UNISWAP_V2_FACTORY = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";

    const LaunchpadFactory = await ethers.getContractFactory("LaunchpadFactory");
    const factory = await LaunchpadFactory.deploy(
        UNISWAP_V2_ROUTER,
        UNISWAP_V2_FACTORY,
        deployer.address // treasury
    );

    await factory.deployTransaction.wait(1);
    
    console.log("LaunchpadFactory deployed to:", factory.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
