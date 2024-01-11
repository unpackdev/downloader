//SPDX-License-Identifier: MIT
// Creator: Roman Gascoin

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

import "./IERC20.sol";

error notWhiteListed();

contract KazokuGenesis is ERC721A, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public marketCap                    = 500;
    uint256 public price_mint                   = 0.075 ether;

    enum locked {CLOSED, PRIVATE, PUBLIC}
    locked public lockState = locked.CLOSED;

    uint8   public cap_whitelist                = 1;
    uint8   public cap_origin                   = 2;
    uint8   public cap_public                   = 2;

    address public  originSigner    = 0x4A97B0DC6E759A61101683f106F90271ea79A56d;
    address public  privateSigner   = 0x2BA0E438fF7bcDA2c8767c0bfB75bC9B2390728b;

    string  private uri_default = 'https://resolver.nftkazoku.com/resolver/999';
    string  private uri_base = '';

    constructor() ERC721A("Kazoku Genesis Collection", "KAZOKU GENESIS") {}

    //-------------------------------------------SETTERS PART----------------------------------------------------------

    /**
     * @dev Change the Contract state for minting purpose.
     */
    function setLock(locked _value)
    onlyOwner external {
        lockState = _value;
    }

    /**
     * @dev change the baseUri for tokenURI function.
     If baseUri is '' the DefaultUri value is used.
     */
    function setBaseUri(string memory _value)
    onlyOwner external {
        uri_base = _value;
    }

    /**
     * @dev The default Uri value if base uri is not set
     This value is used to display black card until the reveal
     */
    function setDefaultUri(string memory _value)
    onlyOwner external {
        uri_default = _value;
    }

    /**
     * @dev Allow the owner of the contract to update the privateSigner
     */
    function setPrivateSigner(address _value)
    onlyOwner external {
        privateSigner = _value;
    }

    /**
     * @dev Allow the owner of the contract to update the privateSigner
     */
    function setOriginSigner(address _value)
    onlyOwner external {
        originSigner = _value;
    }

    //-------------------------------------------MODIFIER PART----------------------------------------------------------

    /**
     * @dev Modifier used for every payment method.
     */
    modifier paymentLimit(uint256 _price) {
        require(msg.value >= _price, "Error: mint price to low.");
        _;
    }

    /**
     * @dev Used with the Contract state, for open or close minting.
     */
    modifier isOpenFor(locked _value) {
        if (_value == locked.PUBLIC) {
            require(lockState == locked.PUBLIC, "Error: Mint is closed.");
        }
        if (_value == locked.PRIVATE) {
            require(lockState != locked.CLOSED, "Error: Mint is closed.");
        }
        _;
    }

    /**
     * @dev Check if the requested minted token is under the marketCap limit
     */
    modifier isMarketCaped(uint256 _quantity) {
        require(totalSupply() + _quantity <= marketCap, "Error: no enough token remaining.");
        _;
    }

    //------------------------------------------TOOLS FUNCTION PART-----------------------------------------------------

    /**
     * @dev Does the user is whitelisted.
     Return 1 for yes else 0.
     */
    function isWhiteList(bytes calldata _signature, address _targetSigner) view internal returns (uint8) {
        if (_targetSigner == keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(uint256(uint160(msg.sender)))
                )).recover(_signature)) {
            return 1;
        }
        return 0;
    }

    /**
     * @dev override the tokenURI function to return a uri_default value during the reveal process
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : uri_default;
    }

    /**
     * @dev override the _baseURI function to return a variable element instead of hardcode string.
     */
    function _baseURI() internal view override returns (string memory) {
        return uri_base;
    }

    //-------------------------------------------MINT FUNCTION PART-----------------------------------------------------

    /**
     * @dev Allow a public user to mint NFT.
     The merkleProof is required to help premium user to bypass public limitation
     */
    function mint_public(uint8 _quantity, bytes calldata _signature, bytes calldata _originSignature)
    external payable
    paymentLimit(price_mint * _quantity)
    isOpenFor(locked.PUBLIC)
    isMarketCaped(_quantity) {
        if (isWhiteList(_signature, privateSigner) == 1) {
            require(balanceOf(_msgSender()) + _quantity <= cap_public + cap_whitelist, "Error: You can't mint more.");
        } else if (isWhiteList(_originSignature, originSigner) == 1) {
            require(balanceOf(_msgSender()) + _quantity <= cap_public + cap_origin, "Error: You can't mint more.");
        } else {
            require(balanceOf(_msgSender()) + _quantity <= cap_public, "Error: You can't mint more.");
        }

        _safeMint(_msgSender(), _quantity);
    }

    /**
     * @dev Private mint for premium users
     */
    function mint_private(uint8 _quantity, bytes calldata _privateSignature, bytes calldata _originSignature)
    external payable
    paymentLimit(price_mint * _quantity)
    isOpenFor(locked.PRIVATE)
    isMarketCaped(_quantity) {
        if (isWhiteList(_privateSignature, privateSigner) == 1) {
            require(balanceOf(_msgSender()) + _quantity <= cap_whitelist, "Error: You can't mint more.");
            _safeMint(_msgSender(), _quantity);
        } else if (isWhiteList(_originSignature, originSigner) == 1) {
            require(balanceOf(_msgSender()) + _quantity <= cap_origin, "Error: You can't mint more.");
            _safeMint(_msgSender(), _quantity);
        } else {
            revert notWhiteListed();
        }

    }

    //---------------------------------------WITHDRAW FUNCTION PART-----------------------------------------------------

    /**
     * @dev Withdraw all of the ETH stored in this contract.
     Give 15 of the amount to the wonderful Rgascoin.
     */
    function withdraw() external onlyOwner {
        uint256 total = address(this).balance;

        payable(0xA2892fF32A7Ea6189c797DB2bEec87076b71bCe2).transfer(total * 15 / 100);
        payable(0xd87c0f9734e3FB6370F12D78Ef02d756e5b2C600).transfer(address(this).balance);
    }

    /**
     * @dev Allow to claim loosed ERC20 stored in this contract.
     */
    function reclaimERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(_msgSender(), erc20Token.balanceOf(address(this)));
    }
}