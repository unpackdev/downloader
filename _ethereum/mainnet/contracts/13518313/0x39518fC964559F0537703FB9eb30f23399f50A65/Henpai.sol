// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";
import "./SaleTrait.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//     .6    9.     6969   .69696     .969696     .969696     .9     //
//    .69    66.   69696  .69696969   .69696969   .69696969   .69    //
//    6%9    6%9  6%9'    6%9   `6%9  6%9   `6%9  6%9   6969  6%9    //
//    6%9    6%9  6%9     6%9    6%9  6%9    6%9  6%9    6%9  6%9    //
//    6%9 6969%9  6&9     6%9    6&9  6%9    6*6  6%9 6969%9  6&9    //
//    6&9  696&9  6&9_69  6&9    6&9  6&9   .6*9  6&9  666%9  6&9    //
//    6&9    6&9  6&9~69  6&9    6&9  6&9_69696   6&9    6&9  6&9    //
//    6&9    6&9  6&9     6&9    6&9  6&9~69690   6&9    6&9  6&9    //
//    6*9    6*9  6*9     6*9    6*9  6*9         6*9    6&9  6*9    //
//    6*9    6*9  6*9.    6*9    6*9  6*9         6*9    6*9  6*9    //
//    6*9    6*9   69696  6*9    6*9  6*9         6*9    6*9  6*9    //
//    696    6*9    6969  6*9    696  6*9         696    6*9  6*9    //
//           69           69          69                 69   69     //
//           9            9           9                  9    9      //
//                                                                   //
///////////////////////////////////////////////////////////////////////

contract Henpai is
    Ownable,
    ERC721,
    ERC721Enumerable,
    VRFConsumerBase,
    SaleTrait,
    ReentrancyGuard
{
    using Address for address;
    using SafeMath for uint256;

    event PermanentURI(string _value, uint256 indexed _id);
    event RandomseedRequested(uint256 timestamp);
    event RandomseedFulfilmentSuccess(
        uint256 timestamp,
        bytes32 requestId,
        uint256 seed
    );
    event RandomseedFulfilmentFail(uint256 timestamp, bytes32 requestId);
    event RandomseedFulfilmentManually(uint256 timestamp);

    address private beneficiaryAddress;

    bool public randomseedRequested = false;
    bool public beneficiaryAssigned = false;

    bytes32 public keyHash;

    uint256 private constant MAX_PRESALE_TX = 10;
    uint256 private constant MAX_PUBLIC_PER_TX = 20;
    uint256 private constant MAX_PRESALE_PER_WALLET = 10;

    uint256 public discountBlockSize = 180;
    uint256 public revealBlock = 0;
    uint256 public seed = 0;

    mapping(address => bool) private _airdropAllowed;
    mapping(address => bool) private _presaleAllowed;
    mapping(address => uint256) private _presaleClaimed;

    string public _defaultURI;
    string public _tokenBaseURI;

    constructor(
        address _coordinator,
        address _linkToken,
        bytes32 _keyHash,
        uint256 _presalePrice,
        uint256 _publicSalePrice,
        string memory name,
        string memory symbol,
        uint256 _maxSupply
    ) ERC721(name, symbol) VRFConsumerBase(_coordinator, _linkToken) {
        keyHash = _keyHash;
        maxSupply = _maxSupply;
        publicSalePrice = _publicSalePrice;
        presalePrice = _presalePrice;
    }

    modifier airdropRoleOnly() {
        require(_airdropAllowed[msg.sender], "Only airdrop role allowed.");
        _;
    }

    modifier beneficiaryOnly() {
        require(
            beneficiaryAssigned && msg.sender == beneficiaryAddress,
            "Only beneficiary allowed."
        );
        _;
    }

    /*************************************************************/
    /* External Functions 
    /*************************************************************/
    function airdrop(address[] memory addresses, uint256 amount)
        external
        airdropRoleOnly
    {
        require(
            totalSupply().add(addresses.length.mul(amount)) <= maxSupply,
            "Exceed max supply limit."
        );

        require(
            totalReserveMinted.add(addresses.length.mul(amount)) <= maxReserve,
            "Insufficient reserve."
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _mintToken(addresses[i], amount);
        }

        totalReserveMinted = totalReserveMinted.add(
            addresses.length.mul(amount)
        );
    }

    function addAirdropRole(address addr) external onlyOwner {
        _airdropAllowed[addr] = true;
    }

    function updateDiscountBlockSize(uint256 blockNumber) external onlyOwner {
        discountBlockSize = blockNumber;
    }

    function setBeneficiary(address addr) external onlyOwner {
        require(addr != address(0), "Beneficiary must not be empty.");
        beneficiaryAddress = addr;
        beneficiaryAssigned = true;
    }

    function setRevealBlock(uint256 blockNumber) external onlyOwner {
        revealBlock = blockNumber;
    }

    function freeze(uint256[] memory ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i += 1) {
            emit PermanentURI(tokenURI(ids[i]), ids[i]);
        }
    }

    function withdraw() external beneficiaryOnly {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*************************************************************/
    /* Public Functions group
    /*************************************************************/
    function mintToken(uint256 amount)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(!msg.sender.isContract(), "Contract is not allowed.");
        require(
            getSaleMode() == 1 || getSaleMode() == 3,
            "Sale not available."
        );

        if (getSaleMode() == 3) {
            require(
                amount <= MAX_PUBLIC_PER_TX,
                "Mint exceed transaction limits."
            );
            require(msg.value >= amount.mul(price()), "Insufficient funds.");
            require(
                totalSupply().add(amount).add(availableReserve()) <= maxSupply,
                "Purchase exceed max supply."
            );
        }

        if (getSaleMode() == 1) {
            require(isWhitelisted(msg.sender), "Not whitelisted.");
            require(amount <= MAX_PRESALE_TX, "Mint exceed transaction limits");
            require(
                _presaleClaimed[msg.sender] + amount <= MAX_PRESALE_PER_WALLET,
                "Mint limit per wallet exceeded."
            );
            require(
                totalPresaleMinted.add(amount) <= presaleCapped,
                "Purchase exceed presale capped."
            );

            require(msg.value >= amount.mul(price()), "Insufficient funds.");
        }

        if (getSaleMode() == 1 || getSaleMode() == 3) {
            _mintToken(msg.sender, amount);
            if (getSaleMode() == 3) {
                totalPublicMinted = totalPublicMinted + amount;
            }
            if (getSaleMode() == 1) {
                _presaleClaimed[msg.sender] =
                    _presaleClaimed[msg.sender] +
                    amount;
                totalPresaleMinted = totalPresaleMinted + amount;
            }
        }

        return true;
    }

    function setSeed(uint256 randomNumber) external onlyOwner {
        randomseedRequested = true;
        seed = randomNumber;
        emit RandomseedFulfilmentManually(block.timestamp);
    }

    function addAllowlist(address[] memory allowlist) external onlyOwner {
        for (uint256 i = 0; i < allowlist.length; i += 1) {
            _presaleAllowed[allowlist[i]] = true;
        }
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function setDefaultURI(string memory defaultURI) external onlyOwner {
        _defaultURI = defaultURI;
    }

    function requestChainlinkVRF() external onlyOwner {
        require(!randomseedRequested, "Chainlink VRF already requested");
        require(
            LINK.balanceOf(address(this)) >= 2000000000000000000,
            "Insufficient LINK"
        );
        requestRandomness(keyHash, 2000000000000000000);
        randomseedRequested = true;
        emit RandomseedRequested(block.timestamp);
    }

    function getSaleMode() public view returns (uint256) {
        uint256 supplyWithoutReserve = maxSupply - maxReserve;
        uint256 mintedWithoutReserve = totalPublicMinted + totalPresaleMinted;

        if (mintedWithoutReserve == supplyWithoutReserve) return 5;

        if (
            closeSale ||
            (publicSale.endBlock > 0 && block.number > publicSale.endBlock)
        ) {
            return 4;
        }

        if (
            publicSale.beginBlock > 0 && block.number >= publicSale.beginBlock
        ) {
            return 3;
        }

        if (
            totalPresaleMinted == presaleCapped ||
            (presale.endBlock > 0 && block.number > presale.endBlock)
        ) {
            return 2;
        }

        if (presale.beginBlock > 0 && block.number >= presale.beginBlock) {
            return 1;
        }

        return 0;
    }

    function startSaleBlock() external view returns (uint256) {
        return getSaleMode() <= 1 ? presale.beginBlock : publicSale.beginBlock;
    }

    function endSaleBlock() external view returns (uint256) {
        return getSaleMode() <= 2 ? presale.endBlock : publicSale.endBlock;
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return _presaleAllowed[addr];
    }

    function tokenBaseURI() external view returns (string memory) {
        return _tokenBaseURI;
    }

    function isRevealed() public view returns (bool) {
        return seed > 0 && revealBlock > 0 && block.number > revealBlock;
    }

    function getMetadata(uint256 tokenId) public view returns (string memory) {
        if (_msgSender() != owner()) {
            require(tokenId < totalSupply(), "Token not exists.");
        }

        if (!isRevealed()) return "default";

        uint256[] memory metadata = new uint256[](maxSupply);

        for (uint256 i = 0; i < maxSupply; i += 1) {
            metadata[i] = i;
        }

        for (uint256 i = 0; i < maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(seed, i))) % (maxSupply));
            (metadata[i], metadata[j]) = (metadata[j], metadata[i]);
        }

        return Strings.toString(metadata[tokenId]);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(tokenId < totalSupply(), "Token not exist.");

        return
            isRevealed()
                ? string(
                    abi.encodePacked(
                        _tokenBaseURI,
                        getMetadata(tokenId),
                        ".json"
                    )
                )
                : _defaultURI;
    }

    function availableReserve() public view returns (uint256) {
        return maxReserve - totalReserveMinted;
    }

    function mintedByMode() external view returns (uint256) {
        if (getSaleMode() == 1) return totalPresaleMinted;
        if (getSaleMode() == 3) return totalPublicMinted;
        return 0;
    }

    function cappedByMode() external view returns (uint256) {
        if (getSaleMode() == 1) return presaleCapped;
        if (getSaleMode() == 3)
            return maxSupply - totalPresaleMinted - maxReserve;
        return 0;
    }

    function availableForSale() external view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function maxTokenPerTx() external view returns (uint256) {
        return getSaleMode() < 3 ? MAX_PRESALE_TX : MAX_PUBLIC_PER_TX;
    }

    function price() public view returns (uint256) {
        if (getSaleMode() == 1) return presalePrice;

        if (getSaleMode() == 3) {
            uint256 passedBlock = block.number - publicSale.beginBlock;
            uint256 discountPrice = passedBlock.div(
                discountBlockSize
            ).mul(1337500000000000);

            if (discountPrice >= publicSalePrice) {
                return 0;
            } else {
                return publicSalePrice.sub(discountPrice);
            }
        }

        return publicSalePrice;
    }

    function isBeneficiary(address addr) external view returns (bool) {
        return beneficiaryAssigned && addr == beneficiaryAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function startPublicSaleBlock() external view returns (uint256) {
        return publicSale.beginBlock;
    }

    function endPublicSaleBlock() external view returns (uint256) {
        return publicSale.endBlock;
    }

    function startPresaleBlock() external view returns (uint256) {
        return presale.beginBlock;
    }

    function endPresaleBlock() external view returns (uint256) {
        return presale.endBlock;
    }

    /*************************************************************/
    /*                    Internal Functions                     */
    /*************************************************************/
    function _mintToken(address addr, uint256 amount) internal returns (bool) {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < maxSupply) _safeMint(addr, tokenIndex);
        }
        return true;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        if (randomNumber > 0) {
            seed = randomNumber;
            emit RandomseedFulfilmentSuccess(block.timestamp, requestId, seed);
        } else {
            seed = 1;
            emit RandomseedFulfilmentFail(block.timestamp, requestId);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
