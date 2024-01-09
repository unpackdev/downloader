// SPDX-License-Identifier: MIT
/// @title: Secret Agent Men: The Farm
/// @author: DropHero LLC
pragma solidity ^0.8.9;

import "./IERC721Enumerable.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

interface ISecretAgentMen is IERC721 {
    function mintTokens(uint16 numberOfTokens, address to) external;
    function burn(uint256 tokenId) external;
}

contract TheFarm is Ownable, ReentrancyGuard, Pausable, ERC721Holder {
    event FataleClaimed(address indexed owner, uint256 indexed tokenId);
    event FataleAndAgentBurned(address indexed owner, uint256 indexed fataleId, uint256 indexed agentId);

    IERC721Enumerable private fatales;
    ISecretAgentMen private secretAgents;

    uint256 public constant MAX_PER_TRANSACTION = 50;

    mapping(uint256 => bool) _fataleMintHasBeenClaimed;
    bool _allowEmergencyFataleWithdrawl = true;

    constructor(address fatalesAddress, address samsAddress) {
        fatales = IERC721Enumerable(fatalesAddress);
        secretAgents = ISecretAgentMen(samsAddress);

        _pause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function fataleHasBeenClaimed(uint256 fataleId) public view returns(bool) {
        return _fataleMintHasBeenClaimed[fataleId];
    }

    function ownedFatalesTokenIds(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokensOwned = fatales.balanceOf(owner);
        uint256[] memory output = new uint256[](tokensOwned);

        for (uint256 i = 0; i < tokensOwned; i++) {
            output[i] = fatales.tokenOfOwnerByIndex(owner, i);
        }

        return output;
    }

    function claimableTokenIds(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory owned = ownedFatalesTokenIds(owner);
        uint256 countOfClaimable = 0;

        for (uint256 i = 0; i < owned.length; i++) {
            if (!fataleHasBeenClaimed(owned[i])) {
                countOfClaimable += 1;
            }
        }

        uint256[] memory output = new uint256[](countOfClaimable);
        uint256 outputIndex = 0;

        for (uint256 i = 0; i < owned.length; i++) {
            if (!fataleHasBeenClaimed(owned[i])) {
                output[outputIndex++] = owned[i];
            }
        }

        return output;
    }

    function trainAgents(uint256[] calldata fatalesIds) external nonReentrant whenNotPaused {
        require(fatalesIds.length > 0, "MINIMUM_MINT_OF_ONE");
        require(
            fatalesIds.length <= MAX_PER_TRANSACTION,
            "MAX_PER_TX_EXCEEDED"
        );

        // Verify ownership of all ids
        for (uint256 i = 0; i < fatalesIds.length; i++) {
            require(
                fatales.ownerOf(fatalesIds[i]) == _msgSender(),
                "FATALE_NOT_OWNED_BY_SENDER"
            );

            require(
                !_fataleMintHasBeenClaimed[fatalesIds[i]],
                "TOKEN_ALREADY_CLAIMED"
            );

            _fataleMintHasBeenClaimed[fatalesIds[i]] = true;
            emit FataleClaimed(_msgSender(), fatalesIds[i]);
        }

        secretAgents.mintTokens(uint16(fatalesIds.length), _msgSender());
    }

    function burnIdentities(uint256 fataleId, uint256 samId) external nonReentrant whenNotPaused {
        require(
            fatales.ownerOf(fataleId) == _msgSender(),
            "FATALE_NOT_OWNED_BY_SENDER"
        );
        require(
            secretAgents.ownerOf(samId) == _msgSender(),
            "AGENT_NOT_OWNED_BY_SENDER"
        );

        emit FataleAndAgentBurned(_msgSender(), fataleId, samId);
        fatales.safeTransferFrom(_msgSender(), address(this), fataleId);
        secretAgents.burn(samId);

        secretAgents.mintTokens(1, _msgSender());
    }

    // In case there's a contract issue we want to give ourselves a temporary escape hatch
    function emergencyTransferFatale(address to, uint256 tokenId) external onlyOwner {
        require(_allowEmergencyFataleWithdrawl, "Emergency exit is closed");

        fatales.safeTransferFrom(address(this), to, tokenId);
    }

    // This cannot be reversed!
    function shutoffEmergencyWithdrawl() external onlyOwner {
        _allowEmergencyFataleWithdrawl = false;
    }
}
