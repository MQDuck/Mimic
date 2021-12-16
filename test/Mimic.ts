import {expect} from 'chai';
import {ethers} from 'hardhat';
import {Contract} from 'ethers';

describe("Mimic", () => {
    let mimic: Contract;

    before(async () => {
       const accounts = await ethers.getSigners();

       const MimicFactory = await ethers.getContractFactory("Mimic");
       mimic = await MimicFactory.deploy();
    });

    it("Test mint", async () => {
        const defaultPrice = await mimic.mintPrice();
        for (let i = 0; i < 1000; ++i) {
            const mintPrice = await mimic.mintPrice();
            console.log(`mint ${i.toString().padStart(3)}:  ${(mintPrice / defaultPrice).toFixed(3)}`);
            await mimic.mint({value: mintPrice.mul(2)});
        }
    })
});