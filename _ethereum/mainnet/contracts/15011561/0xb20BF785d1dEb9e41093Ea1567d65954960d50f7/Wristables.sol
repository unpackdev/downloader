//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

contract WristAficionadoWatchClub is ERC721Upgradeable, OwnableUpgradeable, PaymentSplitterUpgradeable, UUPSUpgradeable {

    using StringsUpgradeable for uint256;

    uint256 constant public MAX_TOKEN_ID = 9999;

    mapping(bytes32 => bool) public claimedWL; // stores hash of address + indexWL

    DutchAuction public dutchAuction; 
    string public _baseTokenURI;

    uint16 public availableTokenId; // max token id available
    uint16 public tokenSupply; // current token supply
    uint8 public indexWL; // index for for drop #
    bool public toggleAuction; // true = dutch auction active, false = mint for flat price active
    bool public saleActive; // if false, mint functions will revert
    uint128 public mintPrice; // price of each token in the `mint` functions

    bytes32 public root; // merkle root 


    modifier SaleActive () {
        require(saleActive, "sale paused");
        _;
    }

    struct DutchAuction {
        uint128 startingPrice;
        uint128 floorPrice;
        uint64  startAt;
        uint64  expiresAt;
        uint128 priceDeductionRate;
    }

    event NewDutchAuction(
        uint128 startingPrice,
        uint128 floorPrice,
        uint64  startAt,
        uint64  expiresAt,
        uint128 priceDeductionRate
    );

    /// @dev See `PaymentSplitter.sol` for documentation on `payees` and `shares_`.
    function initialize( 
        address[] memory payees, 
        uint256[] memory shares_
    ) external initializer {
        __Ownable_init();
         __ERC721_init("Wrist Aficionado Watch Club", "WAWC");
        __PaymentSplitter_init( payees, shares_);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        // necessary to override
    }

    /// @dev sends a specified number of tokens to each address in the `to` array
    function batchAirdrop (address[] calldata to, uint16[] calldata quantity) external payable onlyOwner {
        require(to.length == quantity.length, "[] diff length");
        uint16 length = uint16(to.length);
        uint16 mintIndex = tokenSupply;
        for (uint16 i = 0; i < length; ++i) {
            address a = to[i];
            uint16 quantityForA = quantity[i];
            require(mintIndex + quantityForA <= availableTokenId + 1, "exceeds token supply");
            for (uint16 j = 0; j < quantityForA; ++j) {
                _safeMint(a, mintIndex + j);
            }
            mintIndex += quantityForA;
        }
        tokenSupply = mintIndex;
    }

    /// @dev dutch auction mint
    function mintAuction () external payable SaleActive {
        require(toggleAuction, "use `mint`");
        require(block.timestamp > dutchAuction.startAt , "auction has not started yet" );
        require(block.timestamp < dutchAuction.expiresAt, "auction expired");

        uint timeElapsed = block.timestamp - dutchAuction.startAt;
        uint deduction = dutchAuction.priceDeductionRate * (timeElapsed / 5 minutes); // calculate the number of 5 minute intervals & calculates the deduction from the starting price accordingly
        uint price = deduction > (dutchAuction.startingPrice - dutchAuction.floorPrice) ? dutchAuction.floorPrice : dutchAuction.startingPrice - deduction;

        require(msg.value >= price, "insufficient funds");

        issueToken(msg.sender);
    }

    /// @dev allows users to mint for a flat fee (not a dutch auction)
    function mint () external payable SaleActive {
        require(!toggleAuction, "use `mintAuction`");
        require(msg.value == mintPrice, "incorrect ether sent");

        issueToken(msg.sender);
    }

    /// @dev allows whitelisted users to claim their guarenteed token
    function redeem(bytes32[] calldata proof) external payable {
        require(_verify(_leaf(msg.sender), proof), "Invalid merkle proof");
        require(!toggleAuction, "use `mintAuction`");
        require(msg.value == mintPrice, "incorrect ether sent");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender,indexWL));
        require(!claimedWL[hash], "claimed");
        claimedWL[hash] = true;
        issueToken(msg.sender);
    }    

    /// @dev issues token to recipient
    function issueToken (address recipient) private {
        uint mintIndex = tokenSupply;
        require(mintIndex <= availableTokenId, "exceeds token supply");
        _safeMint(recipient, mintIndex);
        unchecked {
            ++tokenSupply;
        }
    }

    /// @dev ERC2981
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (
            address(this), 
            _salePrice * 6 / 100 // 6% royalty
        );
    }

    /// @dev sets dutch auction struct
    function setDutchAuction ( 
        uint128 _startingPrice,
        uint128 _floorPrice,
        uint64 _startAt,
        uint64 _expiresAt,
        uint128 _priceDeductionRate
        ) external payable onlyOwner {
        dutchAuction = DutchAuction(_startingPrice, _floorPrice, _startAt, _expiresAt, _priceDeductionRate);
        emit NewDutchAuction(_startingPrice, _floorPrice, _startAt, _expiresAt, _priceDeductionRate);
    }

    /// @dev set available token supply
    function setAvailableTokenID (uint16 availableTokenIdIncrease) public payable onlyOwner {
        require(availableTokenId + availableTokenIdIncrease <= MAX_TOKEN_ID, "cannot be greater than 9999");
        availableTokenId += availableTokenIdIncrease;
    }

    /// @dev set price of each token in the `mint` function
    function setMintPrice (uint128 _mintPrice) public payable onlyOwner {
        mintPrice = _mintPrice;
    }

    /// @dev toggles the mode of sale between flat price and dutch auction. false = flat, true = dutch auction
    function setToggleAuction (bool _toggleAuction) external payable onlyOwner {
        toggleAuction = _toggleAuction;
    }

    /// @dev sets the public sale to active. Both mint functions will revert if this is false.
    function setSaleActive (bool _saleActive) public payable onlyOwner {
        saleActive = _saleActive;
    }

    /// @dev allows owner to reset base uri when updating metadata
    function setBaseURI(string memory baseURI) external payable onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @dev allows owner to set the current iteration of the whitelist
    function setIndexWL (uint8 _indexWL) public payable onlyOwner {
        require(_indexWL >= indexWL, "less than current index");
        indexWL = _indexWL;
    }

    /// @dev override token uri to append .json to string
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }


    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    function setAllSaleParams (uint16 _availableTokenId, bytes32 _root, uint8 _indexWL, bool _saleActive, uint128 _mintPrice) external onlyOwner {
        setMerkleRoot(_root);
        setIndexWL(_indexWL);
        setSaleActive(_saleActive);
        setMintPrice(_mintPrice);
        setAvailableTokenID(_availableTokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
}

/// @dev dummy contract for testing upgradeability
contract WristablesV2 is WristAficionadoWatchClub {
    function version() pure public returns (string memory) {
        return "V2";
    }
}
