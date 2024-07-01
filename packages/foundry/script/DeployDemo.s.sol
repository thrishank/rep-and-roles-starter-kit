//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console} from "forge-std/console.sol";

import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import {ReputationTokens} from "@atxdao/contracts/reputation/ReputationTokens.sol";
import {IReputationTokensTypes} from "@atxdao/contracts/reputation/IReputationTokensTypes.sol";
import {Hats} from "../contracts/Hats/Hats.sol";
import {MultiClaimsHatter} from "../contracts/MultiClaimsHatter.sol";
import {ERC1155EligibiltiyModule} from "../contracts/ERC1155EligibiltiyModule.sol";
import {ActiveModule} from "../contracts/ActiveModule.sol";
import {ReputationFaucet} from "../contracts/Reputation/ReputationFaucet.sol";

contract DeployDemoScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    address controller = 0xEc6A9A81659AcdD48509E91Cd9fF2370fb52a197; //replace with burner or other address from wallet!

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        address deployerPubKey = vm.createWallet(deployerPrivateKey).addr;

        vm.startBroadcast(deployerPrivateKey);
        address[] memory admins = new address[](2);
        admins[0] = deployerPubKey;
        admins[1] = controller;

        ReputationTokens instance = new ReputationTokens(
            controller,
            admins,
            admins
        );

        setupAccountWithAllRoles(instance, deployerPubKey);
        setupAccountWithAllRoles(instance, controller);

        ReputationFaucet faucet = new ReputationFaucet(address(instance));
        setupAccountWithAllRoles(instance, address(faucet));

        batchCreateTokens(instance);

        // batchSetTokenURIs(instance);

        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        uint256[] memory mintAmounts = new uint256[](3);
        mintAmounts[0] = 10000;
        mintAmounts[1] = 10000;
        mintAmounts[2] = 10000;

        instance.mintBatch(address(faucet), tokenIds, mintAmounts, "");

        uint256 id;
        assembly {
            id := chainid()
        }

        if (id == 31337) {
            Hats hatsInstance = new Hats("v0.1", "Default IFPS");

            console.log(deployerPubKey);

            uint256 topHatId = hatsInstance.mintTopHat(
                deployerPubKey,
                "Top Hat",
                "TopHat IPFS"
            );
            console.log(topHatId);

            uint256 hatterHatId = hatsInstance.createHat(
                topHatId,
                "Hatter",
                5,
                deployerPubKey,
                deployerPubKey,
                true,
                "Hatter IPFS"
            );

            MultiClaimsHatter hatter = new MultiClaimsHatter(
                "v0.1",
                address(hatsInstance)
            );

            hatsInstance.mintHat(hatterHatId, address(hatter));

            ActiveModule activeModule = new ActiveModule();
            ERC1155EligibiltiyModule eligibilityModule = new ERC1155EligibiltiyModule(
                    address(instance),
                    100
                );
            ERC1155EligibiltiyModule eligibilityModule2 = new ERC1155EligibiltiyModule(
                    address(instance),
                    500
                );
            ERC1155EligibiltiyModule eligibilityModule3 = new ERC1155EligibiltiyModule(
                    address(instance),
                    1500
                );

            uint256 claimableHatId1 = hatsInstance.createHat(
                hatterHatId,
                "Hat of Engineering",
                30,
                address(eligibilityModule),
                address(activeModule),
                true,
                "ipfs://bafkreicff2j67tg5g3klktkk4wavcctorj65y5upkolznwgbhmrakv4dba"
            );

            uint256 claimableHatId2 = hatsInstance.createHat(
                hatterHatId,
                "Hat of Steardship",
                30,
                address(eligibilityModule2),
                address(activeModule),
                true,
                "ipfs://bafkreibfian6fybuifdvchrjspqpedvrkakhwdnyhpwrroustpa7mjtto4"
            );

            uint256 claimableHatId3 = hatsInstance.createHat(
                hatterHatId,
                "Hat of Warden",
                30,
                address(eligibilityModule3),
                address(activeModule),
                true,
                "ipfs://bafkreigvzey77niarqslm6wjd3e77ihwc5rcdrrahp3o6og2dszzzw2fpi"
            );

            console.log(claimableHatId1);
            console.log(claimableHatId2);
            console.log(claimableHatId3);
        }

        vm.stopBroadcast();
    }

    ///////////////////////////////////
    // HELPER FUNCTIONS
    ///////////////////////////////////

    function setupAccountWithAllRoles(
        ReputationTokens instance,
        address addr
    ) public {
        instance.grantRole(instance.TOKEN_UPDATER_ROLE(), addr);
        instance.grantRole(instance.MINTER_ROLE(), addr);
        instance.grantRole(instance.TOKEN_MIGRATOR_ROLE(), addr);
    }

    function batchCreateTokens(ReputationTokens instance) public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;

        IReputationTokensTypes.TokenType[]
            memory tokenTypes = new IReputationTokensTypes.TokenType[](3);
        tokenTypes[0] = IReputationTokensTypes.TokenType.Soulbound;
        tokenTypes[1] = IReputationTokensTypes.TokenType.Redeemable;
        tokenTypes[2] = IReputationTokensTypes.TokenType.Transferable;

        string
            memory BASE_URI = "ipfs://bafybeiaz55w6kf7ar2g5vzikfbft2qoexknstfouu524l7q3mliutns2u4/";

        string[] memory uris = new string[](3);
        uris[0] = string.concat(BASE_URI, "0");
        uris[1] = string.concat(BASE_URI, "1");
        uris[
            2
        ] = "ipfs://bafkreiheocygb3ty4uo3znjw2wz2asjzavn56owlqjoz4cvxvspg64egtq";

        instance.updateTokenBatch(tokenIds, tokenTypes, uris);
    }

    // function batchSetTokenURIs(ReputationTokens instance) public {
    //     string
    //         memory BASE_URI = "ipfs://bafybeiaz55w6kf7ar2g5vzikfbft2qoexknstfouu524l7q3mliutns2u4/";

    //     instance.setTokenURI(0, string.concat(BASE_URI, "0"));
    //     instance.setTokenURI(1, string.concat(BASE_URI, "1"));
    //     instance.setTokenURI(
    //         2,
    //         "ipfs://bafkreiheocygb3ty4uo3znjw2wz2asjzavn56owlqjoz4cvxvspg64egtq"
    //     );
    // }
}
