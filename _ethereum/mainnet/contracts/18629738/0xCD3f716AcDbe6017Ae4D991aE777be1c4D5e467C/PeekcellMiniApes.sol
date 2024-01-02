// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

///////////////////////////////////
//   ___         _          _ _  //
//  | _ \___ ___| |____ ___| | | //
//  |  _/ -_) -_) / / _/ -_) | | //
//  |_| \___\___|_\_\__\___|_|_| //
//  |  \/  (_)_ _ (_)            //
//  | |\/| | | ' \| |            //
//  |_/_\|_|_|_||_|_|___         //
//   / _ \| '_ \/ -_|_-<         //
//  /_/ \_\ .__/\___/__/         //
//        |_                     //
///////////////////////////////////

contract PeekcellMiniApes is ERC721, Ownable {
    using ECDSA for bytes32;

    IERC721 public bayc;
    IERC721 public mini;
    address public expectedSigner;
    uint256 public totalSupply;
    uint256 public constant mintPrice = 0.069 ether;
    string public baseTokenURI;

    error InvalidValue(string message);
    error Unauthorized();

    modifier expectedSignerRecovered(bytes calldata signature, bytes memory args) {
        bytes32 digest = keccak256(abi.encodePacked(args, DOMAIN_SEPARATOR(), keccak256(abi.encode(msg.sender))));
        if (digest.recover(signature) != expectedSigner) revert InvalidValue("Invalid Signature");
        _;
    }

    constructor(string memory baseTokenURI_, string memory name_, string memory symbol_, address expectedSigner_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        expectedSigner = expectedSigner_;
        baseTokenURI = baseTokenURI_;
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32 separator) {
        separator = keccak256(
            abi.encode(keccak256("EIP712Domain(uint256 chainId, address collection)"), block.chainid, address(this))
        );
    }

    function setExpectedSigner(address _expectedSigner) external onlyOwner {
        expectedSigner = _expectedSigner;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBayc(address _bayc) external onlyOwner {
        bayc = IERC721(_bayc);
    }

    function setMini(address _mini) external onlyOwner {
        mini = IERC721(_mini);
    }

    function mint(uint256[] calldata _tokenId) public payable {
        uint256 quantity = _tokenId.length;
        if (msg.value != mintPrice * quantity) revert InvalidValue("Invalid Price");

        for (uint256 i = 0; i < quantity; i++) {
            address ownerAddr = bayc.ownerOf(_tokenId[i]);
            _safeMint(ownerAddr, _tokenId[i]);
            totalSupply++;
        }
    }

    // @dev: burnToRedeem needs to be called by the owner of the mini ape
    // since the token needs to be approved to this contract

    function burnToRedeem(bytes calldata signature, uint256 _miniId, uint256 _baycId)
        external
        expectedSignerRecovered(signature, abi.encodePacked(_miniId, _baycId))
    {
        address miniOwner = mini.ownerOf(_miniId);
        address baycOwner = bayc.ownerOf(_baycId);
        if (msg.sender != miniOwner) revert Unauthorized();

        mini.transferFrom(miniOwner, address(0), _miniId);
        _safeMint(baycOwner, _baycId);
        totalSupply++;
    }

    function withdraw() public onlyOwner {
        address payable devAddr = payable(0xB2AEcc6424F0d6f61533A05373ea88D3CcA8aC6a);
        address payable artAddr = payable(0x2E26ba0064F35712E2EC8970A265C7C0144d902E);

        uint256 balance = address(this).balance;
        uint256 amount1 = (balance * 35) / 100;
        uint256 amount2 = (balance * 65) / 100;
        devAddr.transfer(amount1);
        artAddr.transfer(amount2);
    }

    //@dev: This function is used to withdraw if there is any stuck ETH in the contract
    function withdrawAll() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}