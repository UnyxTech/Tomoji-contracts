
import {
    makeSuiteCleanRoom, owner, tomoErc404Factory,ownerAddress
} from '../__setup.spec';
import { expect } from 'chai';

makeSuiteCleanRoom('create BRC404', function () {
    context('Generic', function () {

        context('Negatives', function () {
            it('User should fail to create BRC404 if not owner.',   async function () {
            });
        })

        context('Scenarios', function () {
            it('Create tomo emoji collection if pass correct param.',   async function () {
                await expect(tomoErc404Factory.connect(owner).createERC404({
                    creator: ownerAddress, 
                    nftTotalSupply: 10000,
                    reserved: 0,
                    maxPerWallet: 100,
                    units: 100,
                    price: 10000,
                    name: "MoMo", 
                    symbol: "Momo", 
                    baseURI: "https://tomo-baseuri/", 
                    contractURI: "https://tomo-contract"
                })).to.not.be.reverted;
            })
        })
    })
})