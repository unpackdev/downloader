// SPDX-License-Identifier: MIT

/*********************************************************
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░  .░░░░░░░░░░░░░░░░░░░░░░░░.  ҹ░░░░░░░░░░░░*
*░░░░░░░░░░░░░  ∴░░░░░░░░░░░░░░░░░░`   ░░․  ░░∴   (░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º   ҹ  ░   (░░░░░░░░*
*░░░░░⁕  .░░░░░░░░░░░░░░░░░░░░░░░     ⁕..    .∴,    ⁕░░░░*
*░░░░░░  ∴░░░░░░░░░░░░░░░░░░░░░░░ҹ ,(º⁕ҹ     ․∴ҹ⁕(. ⁕░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░º`  ․░  ⁕,   ░░░░░░░░*
*░░░░░,  .░░░░░░░░░░░░░░░░░░░░░░░░░`  ,░░⁕  ∴░░   `░░░░░░*
*░░░░░░⁕º░░░░░░░░░░░░░░⁕   ҹ░░░░░░░░░░░░░,  %░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░ҹ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░ҹ   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░º(░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░*
*********************************************************/

pragma solidity ^0.8.6;

import "./ERC165Storage.sol";

import "./ERC5050.sol";
import "./LibERC721AUpgradeable.sol";
import "./ERC5050Storage.sol";
import "./IERC5050.sol";
import "./LibDiamond.sol";
import "./CallProtection.sol";
import "./ISpellsCoin.sol";

import "./SpellsCastStorage.sol";
import "./SpellsStorage.sol";

contract SpellsActionFacet is ERC5050, CallProtection {
    using SpellsCastStorage for SpellsCastStorage.Storage;
    using ERC165Storage for ERC165Storage.Layout;
    using Address for address;

    function initializeSpellsActionFacet(address _spellsCoin) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        SpellsCastStorage.Storage storage es = SpellsCastStorage.getStorage();

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        es.spellsCoin = ISpellsCoin(_spellsCoin);
        es.spellsCoinMultiplier = 1e10 gwei; // 10 tokens per mint unit
        es.tyClaimThreshold = 64;
        es.tyjackpot = 2000 * es.spellsCoinMultiplier;
        es.tyfirstSolveBonus = 1000 * es.spellsCoinMultiplier;

        ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
        erc165.setSupportedInterface(type(IERC5050Sender).interfaceId, true);
        erc165.setSupportedInterface(type(IERC5050Receiver).interfaceId, true);
        _registerAction("cast");
    }

    /// @dev Claim your $DUST from the TYJACKPOT after `tyClaimThreshold` reached.
    function MISCHIEF_MANAGED(address _contract) external {
        SpellsCastStorage.Storage storage es = SpellsCastStorage.getStorage();
        require(!es.tys[_contract], "already claimed");
        require(_contract != address(0), "empty address");
        require(
            es.contractCasts[_contract] >= es.tyClaimThreshold,
            "not enough spells cast on contract"
        );
        // Verify caller is contract owner
        (bool success, bytes memory returnData) = _contract.staticcall(
            abi.encodeWithSignature("owner()")
        );
        require(success, "owner() failed");
        address owner = abi.decode(returnData, (address));
        require(msg.sender == owner, "sender is not owner");

        uint256 amount = es.tyjackpot + es.tyfirstSolveBonus;
        if (es.tyfirstSolveBonus != 0) {
            es.tyfirstSolveBonus = 0;
        }
        es.tyjackpot = (es.tyjackpot / 20) * 19;
        es.tys[_contract] = true;
        es.spellsCoin.mint(msg.sender, amount);
    }
    
    /// @dev Set the claim threshold for TYJACKPOT.
    function setTYClaimThreshold(uint256 _tyClaimThreshold) external protectedCall {
        SpellsCastStorage.getStorage().tyClaimThreshold = _tyClaimThreshold;
    }
    
    function setProxyRegistry(address registry) external protectedCall  {
        ERC5050Storage.setProxyRegistry(registry);
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        if (bytes(a).length != bytes(b).length) {
            return false;
        }
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /// @dev Mine `spellsCoinMultiplier` $DUST to `from` and `to`, each up to 2x initial spellsCoin 
    ///     amount.
    function _mineSpellsCoin(uint256 from, uint256 to) private {
        SpellsCastStorage.Storage storage es = SpellsCastStorage.getStorage();
        uint256 limit = SpellsStorage.mineOpCap(to);
        bool toMaxed = es.tokenSpellsCoinMined[to] >= limit;
        limit = SpellsStorage.mineOpCap(from);
        bool fromMaxed = es.tokenSpellsCoinMined[from] >= limit;
        require(!toMaxed || !fromMaxed, "Spells: both tokens fully mined");
        if (!fromMaxed) {
            es.spellsCoin.mint(address(this), from, es.spellsCoinMultiplier);
            ++es.tokenSpellsCoinMined[from];
        }
        if (!toMaxed) {
            es.spellsCoin.mint(address(this), to, es.spellsCoinMultiplier);
            ++es.tokenSpellsCoinMined[to];
        }
    }

    /// @dev Send ERC-5050 action.
    function sendAction(Action memory action)
        public
        payable
        override
        onlySendableAction(action)
    {
        require(
            LibERC721AUpgradeable.ownerOf(action.from._tokenId) == action.user,
            "Spells: sender does not own token"
        );
        if (
            action.to._address != address(this) &&
            action.to._address.isContract()
        ) {
            ++SpellsCastStorage.getStorage().contractCasts[action.to._address];
        }
        return _sendAction(action);
    }

    /// @dev Wraps `sendAction()` for spell casting.
    function cast(
        uint256 tokenId,
        address to,
        uint256 toTokenId,
        bytes memory data
    ) external payable {
        sendAction(
            Action(
                SpellsCastStorage.CAST_SELECTOR(),
                msg.sender,
                Object(address(this), tokenId),
                Object(to, toTokenId),
                address(0),
                data
            )
        );
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
        require(action.to._tokenId > 0, "Spells: cast to zero token");
        if (action.from._address == address(this)) {
            require(action.from._tokenId > 0, "Spells: cast from zero token");
            require(
                action.user != LibERC721AUpgradeable.ownerOf(action.to._tokenId),
                "Spells: Must be held by different wallets"
            );
            _mineSpellsCoin(action.from._tokenId, action.to._tokenId);
        }
        _onActionReceived(action, _nonce);
    }
}
