//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./LibAppStorage.sol";
import "./IAirdrop.sol";
import "./MerkleProof.sol";

import "./console.sol";

interface IMerkleAirdropRedeemer {
    function airdropRedeemed(
        uint256 tokenSaleId,
        uint256 drop,
        uint256 tokenHash,
        address recipient,
        uint256 amount
    ) external;
    function redeemAirdrop(
        uint256 drop,
        uint256 leaf,
        address recipient,
        uint256 amount,
        uint256 total,
        bytes32[] memory merkleProof
    ) external payable;
}

contract MerkleAirdropFacet is IAirdrop, Modifiers {

    event AirdropAdded(
        uint256 tokenSaleId,
        uint256 drop
    );

    /// @notice airdrops check to see if proof is redeemed
    /// @param drop the id of the airdrop
    /// @param redeemer the merkle proof
    /// @return isRedeemed the amount of tokens redeemed
    function airdropRedeemed(uint256 drop, address redeemer) external view override returns (bool isRedeemed) {
       isRedeemed = _airdropRedeemed(drop, redeemer);
    }

    /// @notice airdrops check to see if proof is redeemed
    /// @param drop the id of the airdrop
    /// @param recipient the merkle proof
    /// @return isRedeemed the amount of tokens redeemed
    function _airdropRedeemed(uint256 drop, address recipient) internal view returns (bool isRedeemed) {
        uint256 red = s.merkleAirdropStorage._totalDataQuantities[drop][recipient];
        uint256 tot = s.merkleAirdropStorage._redeemedDataQuantities[drop][recipient]; // i
        return red != 0 && red == tot;
    }

    /// @notice redeem tokens for airdrop
    /// @param drop the airdrop id
    /// @param leaf the index of the token in the airdrop
    /// @param recipient the beneficiary of the tokens
    /// @param amount tje amount of tokens to redeem
    /// @param merkleProof the merkle proof of the token
    function redeemAirdrop(
        uint256 drop,
        uint256 leaf,
        address recipient,
        uint256 amount,
        uint256 total,
        bytes32[] memory merkleProof
        ) external payable override onlyOwner {

        // check to see if redeemed already
        uint256 _redeemedAmt = s.merkleAirdropStorage._redeemedDataQuantities[drop][recipient];
        uint256 _redeemedttl = s.merkleAirdropStorage._totalDataQuantities[drop][recipient];
        _redeemedttl = _redeemedAmt > 0 ? _redeemedttl : total;

        require(_redeemedAmt + amount <= _redeemedttl, "You have already redeemed this amount");
        s.merkleAirdropStorage._totalDataQuantities[drop][recipient] = _redeemedttl;
        s.merkleAirdropStorage._redeemedDataQuantities[drop][recipient] += amount; // increment amount redeemed

        bool valid = MerkleProof.verify(
            bytes32 (s.merkleAirdropStorage._settings[drop].whitelistHash),
            bytes32 (leaf),
            merkleProof
        );

        // Check the merkle proof
        require(valid, "Merkle proof failed");
    }

    /// @notice add a new airdrop
    /// @param _airdrop the id of the airdrop
    function addAirdrop(AirdropSettings memory _airdrop) public onlyOwner {
        require(s.merkleAirdropStorage._settings[uint256(_airdrop.whitelistId)].whitelistId != _airdrop.whitelistId, "Airdrop already exists");
        s.merkleAirdropStorage._settings[uint256(uint256(_airdrop.whitelistId))] = _airdrop;
    }

    /// @notice Get the token sale settings
    /// @return settings the token sale settings
    function airdrop(uint256 drop) external view override returns (AirdropSettings memory settings) {
        require(s.merkleAirdropStorage._settings[drop].whitelistId == drop, "Airdrop does not exist");
        settings = s.merkleAirdropStorage._settings[drop];
    }

    // init the airdrop, rejecting the tx if already initialized
    function initMerkleAirdrops(AirdropSettings[] calldata settingsList) public onlyOwner {
        require(s.merkleAirdropStorage.numSettings == 0, "Airdrops already initialized");
        require(settingsList.length > 0, "No airdrops provided");

        for (uint256 i = 0; i < settingsList.length; i++) {
            addAirdrop(settingsList[i]);
        }
    }

}
