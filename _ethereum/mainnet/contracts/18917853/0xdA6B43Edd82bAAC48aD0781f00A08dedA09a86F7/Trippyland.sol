// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Trippyland is ERC721AQueryable, Ownable, ReentrancyGuard {
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*                          errors                               */
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    error ErrCannotMintMoreThanMaxSupply();
    error ErrUnderpriced();
    error ErrWithdrawingETH();
    error ErrMintNotOn();

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*                          variables                            */
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    /**
     * @notice Max supply of collection
     */
    uint256 public constant MAX_SUPPLY = 420;

    /**
     * @notice the jngl token
     */
    IERC20 public immutable JNGL;

    /**
     * @notice the AURA token
     */
    IERC20 public immutable AURA;

    /**
     * @notice the SHEESH token
     */
    IERC20 public immutable SHEESH;

    /**
     * @notice the base URI for the collection
     */
    string public baseURI = "ipfs://QmZoAgPaAj43VcWJS9VpkfASTW42nJKuDix3fVBe1qNxbm/";

    /**
     * @notice the price in JNGL to mint 1 trippyland panda
     */
    uint256 public jnglPrice = 1999 ether;

    /**
     * @notice the price in AURA to mint 1 trippyland panda
     */
    uint256 public auraPrice = 5500 ether;

    /**
     * @notice the price in SHEESH to mint 1 trippyland panda
     */
    uint256 public sheeshPrice = 560000000 ether;

    /**
     * @notice the price in ETH to mint 1 trippyland panda
     */
    uint256 public ethPrice = 0.169 ether;

    /**
     * @notice a variable to track if the mint is on or not
     * @dev mint will not be open if this variable is set to false
     */
    bool public mintOn;

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*                        constructor                            */
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    constructor(address _jngl, address _aura, address _sheesh, address _initialMintRecipient)
        Ownable(_initialMintRecipient)
        ERC721A("Trippyland", "TRIPPY")
    {
        JNGL = IERC20(_jngl);
        AURA = IERC20(_aura);
        SHEESH = IERC20(_sheesh);
        _mintERC2309(_initialMintRecipient, 352);
    }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*                          minting                              */
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    /**
     * @notice mint an nft with ETH
     * @param amount - the amount of nfts to mint
     */
    function mintETH(uint256 amount) external payable {
        if (!mintOn) revert ErrMintNotOn();

        uint256 _totalSupply = totalSupply();
        if (amount + _totalSupply > MAX_SUPPLY) {
            revert ErrCannotMintMoreThanMaxSupply();
        }
        if (msg.value < ethPrice * amount) {
            revert ErrUnderpriced();
        }
        _mint(msg.sender, amount);
    }

    /**
     * @notice mint an nft with JNGL
     * @param amount - the amount of nfts to mint
     */
    function mintJNGL(uint256 amount) external nonReentrant {
        if (!mintOn) revert ErrMintNotOn();

        uint256 _totalSupply = totalSupply();
        if (amount + _totalSupply > MAX_SUPPLY) {
            revert ErrCannotMintMoreThanMaxSupply();
        }
        JNGL.transferFrom(msg.sender, address(this), jnglPrice * amount);
        _mint(msg.sender, amount);
    }

    /**
     * @notice mint an nft with AURA
     * @param amount - the amount of nfts to mint
     */
    function mintAURA(uint256 amount) external nonReentrant {
        if (!mintOn) revert ErrMintNotOn();

        uint256 _totalSupply = totalSupply();
        if (amount + _totalSupply > MAX_SUPPLY) {
            revert ErrCannotMintMoreThanMaxSupply();
        }
        AURA.transferFrom(msg.sender, address(this), auraPrice * amount);
        _mint(msg.sender, amount);
    }

    /**
     * @notice mint an nft with SHEESH
     * @param amount - the amount of nfts to mint
     */
    function mintSHEESH(uint256 amount) external nonReentrant {
        if (!mintOn) revert ErrMintNotOn();

        uint256 _totalSupply = totalSupply();
        if (amount + _totalSupply > MAX_SUPPLY) {
            revert ErrCannotMintMoreThanMaxSupply();
        }
        SHEESH.transferFrom(msg.sender, address(this), sheeshPrice * amount);
        _mint(msg.sender, amount);
    }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*                         only owner                            */
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    /**
     * @notice used to open or close hte mint
     */
    function setMintOnStatus(bool status) external onlyOwner {
        mintOn = status;
    }

    /**
     * @notice setter for the eth price
     * @param newPrice - the new eth price per mint
     */
    function setEthPrice(uint256 newPrice) external onlyOwner {
        ethPrice = newPrice;
    }

    /**
     * @notice setter for the jngl price
     * @param newPrice - the new jngl price per mint
     */
    function setJnglPrice(uint256 newPrice) external onlyOwner {
        jnglPrice = newPrice;
    }

    /**
     * @notice setter for the AURA price
     * @param newPrice - the new AURA price per mint
     */
    function setAuraPrice(uint256 newPrice) external onlyOwner {
        auraPrice = newPrice;
    }

    /**
     * @notice setter for the sheesh price
     * @param newPrice - the new sheesh price per mint
     */
    function setSheeshPrice(uint256 newPrice) external onlyOwner {
        sheeshPrice = newPrice;
    }

    /**
     * @notice setter for the base URI
     * @param newBaseURI - new base URI to use for tokens
     */
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @notice sends all the eth in the contract to the owner
     */
    function withdrawETH() external onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!os) revert ErrWithdrawingETH();
    }

    /**
     * @notice sends the balance of this contract's `erc20` balance to the owner
     * @param erc20 - the token address to claim from
     */
    function withdrawERC20(address erc20) external onlyOwner {
        IERC20 token = IERC20(erc20);
        token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)));
    }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*                       view functions                          */
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    /*                           overrides                           */
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }
}
