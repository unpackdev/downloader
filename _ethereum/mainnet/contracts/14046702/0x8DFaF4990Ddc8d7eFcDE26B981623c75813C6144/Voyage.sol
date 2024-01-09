// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dao: MEME
/// @author: Wizard

import "./ERC721Redeemable.sol";
import "./ERC2981PerTokenRoyalties.sol";

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Address.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address account, uint256 amount) external;
}

interface IERC1155 {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

contract Voyage is
    ERC721,
    ERC721Burnable,
    ERC721Redeemable,
    ERC2981PerTokenRoyalties,
    Ownable,
    AccessControl
{
    using SafeMath for uint256;
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _contractURI;
    IERC20 public fuelToken;
    IERC1155 public dontBurnMeme;
    uint256 private fuelRequired = 20000000 * 1e18;
    uint256 private success = 33333;
    uint256 private failure = 66666;
    bool public allowRedemptions = false;

    event Launch(uint256 fuel, uint256 token);

    constructor(address _fuelToken, address _dontBurnMeme)
        ERC721("Voyage", "VOYAGE")
    {
        fuelToken = IERC20(_fuelToken);
        dontBurnMeme = IERC1155(_dontBurnMeme);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CONTROLLER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    modifier onlyController() {
        require(
            hasRole(CONTROLLER_ROLE, _msgSender()),
            "caller is not a controller"
        );
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
        _;
    }

    modifier redemptionsAllowed() {
        require(allowRedemptions, "redemptions not open");
        _;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function setBaseURI(uint256 redeemable, string memory uri)
        public
        onlyController
    {
        _setBaseURI(redeemable, uri);
    }

    function setAllowRedemptions(bool allow) public onlyController {
        allowRedemptions = allow;
    }

    function mint(uint256 tokenId, address to) public virtual onlyMinter {
        _mint(tokenId, to);
    }

    function create(
        uint256 id,
        uint256 allowedRedemptions,
        uint256 expiresAt,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyController {
        _create(id, allowedRedemptions, expiresAt, uri);

        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
    }

    function launch(uint256 fuel) public {
        require(msg.sender == tx.origin, "no contracts");
        require(
            fuelToken.balanceOf(_msgSender()) >= fuel,
            "do you have fuel?"
        );
        require(
            dontBurnMeme.balanceOf(_msgSender(), 3) >= 1,
            "do you have a rocket?"
        );

        uint256 tokenToMint;

        dontBurnMeme.burn(_msgSender(), 3, 1);
        fuelToken.burnFrom(_msgSender(), fuel);
        uint256 random = determanisticRandom();

        if (fuel == fuelRequired) tokenToMint = success;
        else tokenToMint = random > 1 ? failure : success;

        _mint(tokenToMint, _msgSender());
        emit Launch(fuel, tokenToMint);
    }

    function determanisticRandom() private view returns (uint256) {
        // this is for fun and random enough
        uint256 random = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );
        return random.mod(5).add(1);
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override(ERC2981PerTokenRoyalties)
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 redeemableId = redeemableIdForTokenId(tokenId);
        RoyaltyInfo memory royalties = _royalties[redeemableId];
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721Redeemable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function redeem(uint256 tokenId, uint256 amount)
        public
        virtual
        override(ERC721Redeemable)
        redemptionsAllowed
    {
        super.redeem(tokenId, amount);
    }

    function redeemFrom(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public virtual override(ERC721Redeemable) redemptionsAllowed {
        super.redeemFrom(from, tokenId, amount);
    }
}
