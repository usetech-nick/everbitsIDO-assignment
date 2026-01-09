import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("EverbitsIDO - max tokens per wallet", function () {
    let deployer: SignerWithAddress;
    let user: SignerWithAddress;

    let factory: any;
    let ido: any;

    beforeEach(async function () {
        [deployer, user] = await ethers.getSigners();beforeEach(async function () {
    [deployer, user] = await ethers.getSigners();

    const DummyRouter = await ethers.getContractFactory("DummyRouter");
    const dummyRouter = await DummyRouter.deploy();
    await dummyRouter.deployed();

    const Factory = await ethers.getContractFactory("LaunchpadFactory");
    factory = await Factory.deploy(
        dummyRouter.address,              // router
        ethers.constants.AddressZero,     // factory (unused in test)
        deployer.address                  // treasury
    );
    await factory.deployed();

    const now = (await ethers.provider.getBlock("latest")).timestamp;

    const params = {
        name: "Everbits",
        symbol: "EVB",
        totalSupply: ethers.utils.parseEther("1000"),
        idoSupply: ethers.utils.parseEther("100"),
        liquidityPercentage: 5000,
        softCap: ethers.utils.parseEther("10"),
        hardCap: ethers.utils.parseEther("100"),
        startTimestamp: now,
        endTimestamp: now + 3600,
        liquidityLockDuration: 3600,
        maxTokensPerWallet: ethers.utils.parseEther("10"),
    };

    const tx = await factory.createStandardIDO(params);
    const receipt = await tx.wait();

    const event = receipt.events?.find(
        (e: any) => e.event === "StandardIDOCreated"
    );

    ido = await ethers.getContractAt("EverbitsIDO", event.args._ido);
});


    const DummyRouter = await ethers.getContractFactory("DummyRouter");
    const dummyRouter = await DummyRouter.deploy();
    await dummyRouter.deployed();

    factory = await Factory.deploy(
        dummyRouter.address,
        ethers.constants.AddressZero,
        deployer.address
    );

        const now = (await ethers.provider.getBlock("latest")).timestamp;

        // Create IDO with maxTokensPerWallet = 10
        const params = {
            name: "Everbits",
            symbol: "EVB",
            totalSupply: ethers.utils.parseEther("1000"),
            idoSupply: ethers.utils.parseEther("100"),
            liquidityPercentage: 5000,
            softCap: ethers.utils.parseEther("10"),
            hardCap: ethers.utils.parseEther("100"),
            startTimestamp: now,
            endTimestamp: now + 3600,
            liquidityLockDuration: 3600,
            maxTokensPerWallet: ethers.utils.parseEther("10"),
        };

        const tx = await factory.createStandardIDO(params);
        const receipt = await tx.wait();

        const event = receipt.events.find(
            (e: any) => e.event === "StandardIDOCreated"
        );

        ido = await ethers.getContractAt("EverbitsIDO", event.args._ido);
        
    });


    it("allows contribution within max token limit", async function () {
        // maxTokensPerETH = idoSupply / hardCap = 100 / 100 = 1 token per ETH
        // maxTokensPerWallet = 10 → max ETH allowed = 10

        await expect(
            ido.connect(user).contribute(
                ethers.utils.parseEther("10"),
                { value: ethers.utils.parseEther("10") }
            )
        ).to.not.be.reverted;
    });

    it("reverts when contribution exceeds max token limit", async function () {
        // 11 ETH → 11 tokens in worst case → exceeds limit

        await expect(
            ido.connect(user).contribute(
                ethers.utils.parseEther("11"),
                { value: ethers.utils.parseEther("11") }
            )
        ).to.be.revertedWith("Max tokens per wallet exceeded");
    });
});
