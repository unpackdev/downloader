// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC1155Holder.sol";
import "./IERC1155.sol";
import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./IMint.sol";
import "./ILandPiece.sol";

struct SupportedToken {
    IERC20 tokenAddress;
    uint256 conversionRate;
    uint8 tokenId;
    string symbol;
    bool initialized;
    bool supported;
}

struct BundleInfo {
    uint256 index;
    uint8 nr;
    uint64 quantity;
}

contract MintManager is
    Initializable,
    OwnableUpgradeable,
    IERC721Receiver,
    ERC1155Holder
{
    uint256 public price;

    IMintNFT public rabbyAddress;
    IMintNFT public owlAddress;
    IERC1155 public bundleAddress;
    ILandPiece public landPieceAddress;
    uint256 public base;

    mapping(uint8 => BundleInfo) public bundles;

    uint16 public NR_OF_SUPPORTED_TOKEN;
    mapping(uint8 => SupportedToken) public supportedToken;

    bool public publicMint;
    bool public whitelistMint;
    address public dummy;

    bytes32 public allowRoot;
    mapping(address => uint8) public whitelistClaims;
    bytes32 public bundleRoot;

    function initialize(
        IMintNFT _rabby,
        IMintNFT _owl,
        IERC1155 _bundle,
        ILandPiece _land
    ) public initializer {
        __Ownable_init();
        rabbyAddress = _rabby;
        owlAddress = _owl;
        bundleAddress = _bundle;
        landPieceAddress = _land;
        bundles[0].index = 100;
        bundles[1].index = 400;
        bundles[2].index = 670;
        bundles[3].index = 1010;
        bundles[0].nr = 60;
        bundles[1].nr = 27;
        bundles[2].nr = 17;
        bundles[3].nr = 15;
        bundles[0].quantity = 5;
        bundles[1].quantity = 10;
        bundles[2].quantity = 20;
        bundles[3].quantity = 50;
        base = 1e16;
    }

    function mintWhitelist(uint8 num, bytes32[] calldata _proof)
        external
        payable
    {
        require(msg.value >= calculatePrice(num, 0));
        require(whitelistClaims[msg.sender] <= 25 - num);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, allowRoot, leaf));
        require(whitelistMint);

        rabbyAddress.mintFor(msg.sender, num);
        whitelistClaims[msg.sender] += num;
    }

    function mintBundleWhitelist(uint8 id, bytes32[] calldata _proof)
        external
        payable
    {
        require(msg.value >= calculatePriceBundle(id, 0));
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, bundleRoot, leaf));
        require(whitelistMint);

        _mintBundle(id, msg.sender);
    }

    function mintBundleWhitelistByCustomToken(
        uint8 id,
        uint256 amount,
        uint8 tokenIndex,
        bytes32[] calldata _proof
    ) external payable {
        require(supportedToken[tokenIndex].initialized);
        require(amount >= calculatePriceBundle(id, tokenIndex));
        require(whitelistMint);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, bundleRoot, leaf));
        IERC20(supportedToken[tokenIndex].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        _mintBundle(id, msg.sender);
    }

    function mintWhitelistByCustomToken(
        uint256 amount,
        uint8 num,
        uint8 tokenIndex,
        bytes32[] calldata _proof
    ) external {
        require(supportedToken[tokenIndex].initialized);
        require(amount >= calculatePrice(num, tokenIndex));
        require(whitelistMint);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, allowRoot, leaf));

        IERC20(supportedToken[tokenIndex].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        rabbyAddress.mintFor(msg.sender, num);
        whitelistClaims[msg.sender] += num;
    }

    function mintByCustomToken(
        uint256 amount,
        uint8 num,
        uint8 tokenIndex
    ) external {
        require(supportedToken[tokenIndex].initialized);
        require(amount >= calculatePrice(num, tokenIndex));
        require(publicMint);

        IERC20(supportedToken[tokenIndex].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        rabbyAddress.mintFor(msg.sender, num);
    }

    function mint(uint8 num) external payable {
        require(msg.value >= calculatePrice(num, 0));
        require(publicMint);
        rabbyAddress.mintFor(msg.sender, num);
    }

    function redeemBundle(uint8 id) external {
        // burn the bundle, since IERC1155 doesn't support burn, send to dummy address
        bundleAddress.safeTransferFrom(msg.sender, dummy, id, 1, "");

        // mint rabby
        rabbyAddress.transferBundle(
            msg.sender,
            bundles[id].index,
            bundles[id].quantity
        );
        bundles[id].index += bundles[id].quantity;

        // mint owl
        if (id == 3) {
            owlAddress.mintFor(msg.sender, 1);
        }

        if (id >= 2) {
            landPieceAddress.mintFor(msg.sender, 1);
        }
    }

    function buyBundle(uint8 id) external payable {
        require(msg.value >= calculatePriceBundle(id, 0));
        require(publicMint);
        _mintBundle(id, msg.sender);
    }

    function presaleBundle(uint8 id, address to) external onlyOwner {
        _mintBundle(id, to);
    }

    function buyBundleByCustomToken(
        uint8 id,
        uint256 amount,
        uint8 tokenIndex
    ) external {
        require(supportedToken[tokenIndex].initialized);
        require(amount >= calculatePriceBundle(id, tokenIndex));
        require(publicMint);
        IERC20(supportedToken[tokenIndex].tokenAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        _mintBundle(id, msg.sender);
    }

    function calculatePriceBundle(uint8 id, uint8 tokenIndex)
        public
        view
        returns (uint256)
    {
        if (tokenIndex == 0) {
            return price * base * bundles[id].quantity;
        } else {
            return
                ((price * base * bundles[id].quantity) *
                    supportedToken[tokenIndex].conversionRate) / 10**3;
        }
    }

    function calculatePrice(uint64 num, uint8 tokenIndex)
        public
        view
        returns (uint256)
    {
        if (tokenIndex == 0) {
            return price * base * num;
        } else {
            return
                ((price * base * num) *
                    supportedToken[tokenIndex].conversionRate) / 10**3;
        }
    }

    ///////////////////////////////////////////////////
    // VIEW FUNCTION
    ///////////////////////////////////////////////////

    function totalRabbyMinted() public view returns (uint256) {
        return
            IERC721Enumerable(address(rabbyAddress)).totalSupply() -
            (uint256(bundles[0].nr) * 5) -
            (uint256(bundles[1].nr) * 10) -
            (uint256(bundles[2].nr) * 20) -
            (uint256(bundles[3].nr) * 50);
    }

    ///////////////////////////////////////////////////
    // PRIVATE FUNCTION
    ///////////////////////////////////////////////////

    function _mintBundle(uint8 id, address to) private {
        bundleAddress.safeTransferFrom(address(this), to, id, 1, "");
        bundles[id].nr--;
    }

    // we override the receiver method
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    ///////////////////////////////////////////////////
    // ADMIN FUNCTION
    ///////////////////////////////////////////////////

    function setRoot(bytes32 _root) public onlyOwner {
        allowRoot = _root;
    }

    function setBundleRoot(bytes32 _root) public onlyOwner {
        bundleRoot = _root;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setDummy(address _dummy) public onlyOwner {
        dummy = _dummy;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function setNftAddress(IMintNFT _rabby) public onlyOwner {
        rabbyAddress = _rabby;
    }

    function setOwlAddress(IMintNFT _owl) public onlyOwner {
        owlAddress = _owl;
    }

    function setBundleAddress(IERC1155 _bundleAddress) public onlyOwner {
        bundleAddress = _bundleAddress;
    }

    function setLandAddress(ILandPiece _landAddress) public onlyOwner {
        landPieceAddress = _landAddress;
    }

    function setSupportedToken(
        uint8 tokenId,
        IERC20 tokenAddress,
        uint256 conversionRate,
        string calldata symbol
    ) public onlyOwner {
        require(tokenId > 0, "should put tokenId > 0");
        if (!supportedToken[tokenId].initialized) {
            NR_OF_SUPPORTED_TOKEN++;
        }
        supportedToken[tokenId].initialized = true;
        supportedToken[tokenId].supported = true;
        supportedToken[tokenId].tokenAddress = tokenAddress;
        supportedToken[tokenId].conversionRate = conversionRate;
        supportedToken[tokenId].symbol = symbol;
        supportedToken[tokenId].tokenId = tokenId;
    }

    function turnOffSupportedToken(uint8 tokenId) public onlyOwner {
        require(tokenId > 0, "should put tokenId > 0");
        require(supportedToken[tokenId].initialized == true);
        supportedToken[tokenId].supported = false;
    }

    function turnOnSupportedToken(uint8 tokenId) public onlyOwner {
        require(tokenId > 0, "should put tokenId > 0");
        require(supportedToken[tokenId].initialized == true);
        supportedToken[tokenId].supported = true;
    }

    function toggleWhitelist() public onlyOwner {
        whitelistMint = !whitelistMint;
    }

    function togglePublicMint() public onlyOwner {
        publicMint = !publicMint;
    }
}
