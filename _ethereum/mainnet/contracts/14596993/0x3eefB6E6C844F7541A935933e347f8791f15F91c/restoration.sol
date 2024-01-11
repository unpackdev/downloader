// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Ownable.sol";

abstract contract DemonicScullsContract {
    function mintForAddress(address wallet, uint256 level, uint256 id) external virtual;
    function mintRefund(address wallet) external virtual;
    function setClaimedId(uint256 id) external virtual;
}

contract DemonicSkullsRestoration is Ownable {

    DemonicScullsContract demonicSkullsContract;

    struct MinterInput {
        address wallet;
        uint256[] ids;
    }

    mapping(uint256 => address) minters;
    mapping(uint256 => uint256[]) mintedIds;

    uint256 private constant LEVEL_ONE_BLOOD_AMOUNT = 1;
    uint256 private constant LEVEL_TWO_BLOOD_AMOUNT = 3;
    uint256 private constant LEVEL_THREE_BLOOD_AMOUNT = 5;

    bool public levelOneClaimed = false;
    bool public levelTwoClaimed = false;
    bool public levelThreeClaimed = false;
    uint256 mintersAmount = 0;
    uint256[] claimedIds;

    constructor(
        address[] memory mintersAddresses,
        uint256[][] memory ids,
        uint256[] memory claimedCryptoSkulls) {

        for (uint256 i = 0; i < mintersAddresses.length; i++) {
            minters[i] = mintersAddresses[i];
            mintedIds[i] = ids[i];
            mintersAmount++;
        }
        claimedIds = claimedCryptoSkulls;
    }

    function setDemonicSkullsContract(address dsContractAddress) public onlyOwner {
        demonicSkullsContract = DemonicScullsContract(dsContractAddress);
    }

    function setClaimedIds() public onlyOwner {
        for (uint256 i = 0; i < claimedIds.length; i++) {
            demonicSkullsContract.setClaimedId(claimedIds[i]);
        }
    }

    function claimLevelOnes() public onlyOwner {
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id < 10000) {
                    demonicSkullsContract.mintForAddress(minters[i], LEVEL_ONE_BLOOD_AMOUNT, id);
                }
            }
        }
        levelOneClaimed = true;
    }

    function claimLevelTwos() public onlyOwner {
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id > 9999 && id < 12500) {
                    demonicSkullsContract.mintForAddress(minters[i], LEVEL_TWO_BLOOD_AMOUNT, id);
                }
            }
        }
        levelTwoClaimed = true;
    }

    function claimLevelThrees() public onlyOwner {
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id > 12499 && id < 12650) {
                    demonicSkullsContract.mintForAddress(minters[i], LEVEL_THREE_BLOOD_AMOUNT, id);
                }
            }
        }
        levelThreeClaimed = true;
    }

    function claimScrewedOnes() public onlyOwner {
        require(levelTwoClaimed, "You must claim level 2 first!");
        for (uint256 i = 0; i < mintersAmount;  i++) {
            uint256[] memory ids = mintedIds[i];
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 id = ids[j];
                if (id > 12649) {
                    demonicSkullsContract.mintRefund(minters[i]);
                }
            }
        }
    }

}
