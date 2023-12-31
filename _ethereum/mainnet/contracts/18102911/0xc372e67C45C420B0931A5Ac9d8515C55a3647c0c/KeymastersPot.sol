// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./IERC721A.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

//                                .__        ___.
//  ____________ _______   ____    |  | _____ \_ |__   ______
//  \_  __ \__  \\_  __ \_/ __ \   |  | \__  \ | __ \ /  ___/
//   |  | \// __ \|  | \/\  ___/   |  |__/ __ \| \_\ \\___ \
//   |__|  (____  /__|    \___  >  |____(____  /___  /____  >
//              \/            \/             \/    \/     \/
//
// Apepe Odyssey Chapter 1: Keymasters' Pot
// only those who possess the key will reap the rewards
//

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

contract KeymastersPot is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    IDelegationRegistry dc;
    IERC721A public odysseyKey;
    address public claimAssistant;
    uint256 public totalDepositedETH;
    uint256 numOfKeys;

    mapping(uint256 => uint256) public lastClaimed; // records the point (totalDepositedETH) for when a key was claimed

    event KeyRewardClaimed(uint256 tokenId, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {}

    function initialize(
        IERC721A _keyAddress,
        IDelegationRegistry _dc
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        odysseyKey = _keyAddress;
        dc = _dc;
        numOfKeys = 224;
        _pause();
    }

    receive() external payable {
        totalDepositedETH += msg.value;
    }

    fallback() external payable {
        totalDepositedETH += msg.value;
    }

    // the function that keymasters should call, to claim their rewards
    function claimEth(
        uint256[] memory ids, // key ids
        address _vault // if no delegate, pass _vault as 0x0000000000000000000000000000000000000000
    ) external nonReentrant whenNotPaused {
        uint256 amountToClaim;
        address requester = msg.sender;
        for (uint256 i; i < ids.length; i++) {
            if (_vault != address(0)) {
                bool isDelegateValid = dc.checkDelegateForToken(
                    msg.sender,
                    _vault,
                    address(odysseyKey),
                    ids[i]
                );
                require(isDelegateValid, "Not a delegate for the vault.");
                requester = _vault;
            }
            require(odysseyKey.ownerOf(ids[i]) == requester, "Not the owner");
            amountToClaim += claimEthForKey(ids[i]);
        }
        require(amountToClaim > 0, "Nothing to claim");
        (bool success, ) = requester.call{value: amountToClaim}("");
        require(success, "Transfer failed.");
    }

    // a util function for viewing pending rewards for keys. wraps around claimableEthForKey
    function claimableEth(
        uint256[] memory ids
    ) external view returns (uint256[] memory) {
        uint256[] memory claimableAmounts = new uint256[](ids.length);
        for (uint256 i; i < ids.length; i++) {
            claimableAmounts[i] = claimableEthForKey(ids[i]);
        }
        return claimableAmounts;
    }

    // an internal util function used by claimEth function that also records whenever a claim is made
    function claimEthForKey(uint256 tokenId) internal returns (uint256) {
        uint256 amountToClaim;
        if (totalDepositedETH > lastClaimed[tokenId]) {
            amountToClaim = ((totalDepositedETH - lastClaimed[tokenId]) /
                numOfKeys);
            emit KeyRewardClaimed(tokenId, amountToClaim);
            lastClaimed[tokenId] = totalDepositedETH;
        } else {
            amountToClaim = 0;
        }
        return amountToClaim;
    }

    // an internal util function used by claimableEth - takes token id and return the claimable amount associated to that token
    function claimableEthForKey(
        uint256 tokenId
    ) internal view returns (uint256) {
        uint256 amountToClaim;
        if (totalDepositedETH > lastClaimed[tokenId]) {
            amountToClaim = ((totalDepositedETH - lastClaimed[tokenId]) /
                numOfKeys);
        } else {
            amountToClaim = 0;
        }
        return amountToClaim;
    }

    function assistClaim(uint256[] memory ids) external nonReentrant {
        require(msg.sender == claimAssistant, "Caller not the assistant");

        for (uint256 i; i < ids.length; i++) {
            address receiver = odysseyKey.ownerOf(ids[i]);
            uint256 amountToClaim;
            if (totalDepositedETH > lastClaimed[ids[i]]) {
                amountToClaim = ((totalDepositedETH - lastClaimed[ids[i]]) /
                    numOfKeys);
                emit KeyRewardClaimed(ids[i], amountToClaim);
                lastClaimed[ids[i]] = totalDepositedETH;
            } else {
                amountToClaim = 0;
            }

            if (amountToClaim > 0) {
                (bool success, ) = receiver.call{value: amountToClaim}("");
                require(success, "Transfer failed.");
            }
        }
    }

    function setAssistant(address _newAssistant) external onlyOwner {
        claimAssistant = _newAssistant;
    }

    function pause() external onlyOwner() {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
