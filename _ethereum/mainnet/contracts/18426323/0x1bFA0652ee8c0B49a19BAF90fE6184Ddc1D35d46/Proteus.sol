// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**                
.--.           .                     
|   )         _|_                    
|--' .--. .-.  |   .-. .  . .--.     
|    |   (   ) |  (.-' |  | `--.     
'    '    `-'  `-' `--'`--`-`--'                                         
*/

/**
 * @title Proteus
 * @author dev [at] proteus dot fyi
 */

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";

import "./ProteusPool.sol";

error ChangePriceTooLow();
error PaidWhenFree();
error MaxSupply();
error WithdrawTransfer();
error ZeroAddressForbidden();
error OnlyMinterOrOwner();

contract Proteus is ReentrancyGuard, ERC721, ERC2981, Ownable {
    using Address for address payable;

    uint16 public currentTokenId = 0;
    uint16 public tokenIdMax = 1_024;

    uint256 public constant FEE_DELTA = 0.003 ether;
    uint256 public constant TIME_DELTA = 5 days;

    // Fee calc %
    uint256 public constant POOL_NUMER = 600;
    uint256 public constant OWNER_NUMER = 300;
    uint256 public constant SPLIT_DENOM = 1000; // implicit team at 10%

    string public defaultURI;

    address public minterContract; // Auction
    uint96 public constant royaltyFee = 500; // 5%

    address public immutable team;
    ProteusPool public immutable pool;

    mapping(uint256 => string) private metadata;
    mapping(uint256 => uint256) public paidChangesNonce;
    mapping(uint256 => uint256) public lastPaidChangeTime;
    mapping(uint256 => uint256) public nextFreeChange;

    constructor(
        address payable _team,
        string memory _defaultURI
    ) ERC721("Proteus", unicode"Δ") {
        team = _team;
        defaultURI = _defaultURI;
        pool = new ProteusPool();
        _setDefaultRoyalty(_team, royaltyFee);
    }

    // - - - - - - - - - - - - - -
    //  External Data
    // - - - - - - - - - - - - - -
    function totalSupply() external view returns (uint256) {
        return currentTokenId;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // = = = = = = = = = = = = = = = =

    // - - - - - - - - - - - - - -
    //  Owner Functions
    // - - - - - - - - - - - - - -
    function setMinterContract(address newMinterContract) external onlyOwner {
        if (newMinterContract == address(0)) revert ZeroAddressForbidden();
        minterContract = newMinterContract;
    }

    function mint(address to) external {
        if ((msg.sender != minterContract) && (msg.sender != owner())) {
            revert OnlyMinterOrOwner();
        }
        if (currentTokenId >= tokenIdMax) revert MaxSupply();
        _safeMint(to, ++currentTokenId);
    }

    function endMint() external onlyOwner {
        tokenIdMax = currentTokenId;
    }

    // = = = = = = = = = = = = = = = =

    // - - - - - - - - - - - - - - - -
    //  URI
    // - - - - - - - - - - - - - - - -
    function changeFee(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        return (paidChangesNonce[tokenId] + 1) * FEE_DELTA;
    }

    function freeChangeIsUnlocked(uint256 tokenId) public view returns (bool) {
        uint256 threshold = (paidChangesNonce[tokenId] * TIME_DELTA);
        if (block.timestamp >= (lastPaidChangeTime[tokenId] + (threshold))) {
            return true;
        }
        return false;
    }

    function setTokenURI(
        uint256 tokenId,
        string calldata uri
    ) external payable nonReentrant {
        if (
            (ownerOf(tokenId) == msg.sender) &&
            (freeChangeIsUnlocked(tokenId)) &&
            (block.timestamp > nextFreeChange[tokenId])
        ) {
            // Free
            if (msg.value > 0) revert PaidWhenFree();
            nextFreeChange[tokenId] = (block.timestamp + TIME_DELTA);
            metadata[tokenId] = uri;
        } else {
            // Paid
            uint256 fee = changeFee(tokenId);
            if (fee > msg.value) revert ChangePriceTooLow();

            lastPaidChangeTime[tokenId] = block.timestamp;
            paidChangesNonce[tokenId]++;
            metadata[tokenId] = uri;

            uint256 poolAmount = ((fee * POOL_NUMER) / SPLIT_DENOM);
            uint256 ownerAmount = ((fee * OWNER_NUMER) / SPLIT_DENOM);

            pool.contributeFor{value: poolAmount}(msg.sender);
            // no revert incase griefed with always revert function
            ownerOf(tokenId).call{value: ownerAmount, gas: 5000}("");
            payable(team).sendValue(address(this).balance);
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return
            bytes(metadata[tokenId]).length > 0
                ? metadata[tokenId]
                : defaultURI;
    }

    // = = = = = = = = = = = = = = = =

    // - - - - - - - - - - - - - - - -
    //  Pool Access
    // - - - - - - - - - - - - - - - -
    function claimPoolForPeriod(uint256 period) external {
        pool.claimPeriodPool(payable(msg.sender), period);
    }
    // = = = = = = = = = = = = = = = =
}
