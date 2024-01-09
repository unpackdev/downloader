// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BigStonedWolfClub is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAXSUPPLY = 4444;
    uint256 public constant MAX_SELF_MINT = 10;
    address private signerAddress = 0xd8C160C3104017b443C08ec28bC83E9a4DD0fdc1;
    address public mainAddress = 0xcf3668e8ec1eC899a7Cd5a13DF40f425A91c7552;
    string public baseURI;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut
    }

    WorkflowStatus public workflow;


    constructor(
        string memory _initBaseURI
    ) ERC721("BigStonedWolfClub", "BSWC") {
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
    }

    //GETTERS

    function publicSaleLimit() public pure returns (uint256) {
        return MAXSUPPLY;
    }

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

   function hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encode(sender));
    }

   function isValidData(bytes32 message,bytes memory sig) private
        view returns (bool) {
        return (recoverSigner(message, sig) == signerAddress);
    }



    function recoverSigner(bytes32 message, bytes memory sig)
       public
       pure
       returns (address)
        {
       uint8 v;
       bytes32 r;
       bytes32 s;

       (v, r, s) = splitSignature(sig);
       return ecrecover(message, v, r, s);
        }

   function splitSignature(bytes memory sig)
       public
       pure
       returns (uint8, bytes32, bytes32)
    {
       require(sig.length == 65);
       
       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
    }


    function presaleMint(bytes32 messageHash, bytes calldata signature, uint256 ammount)
    external
    payable
    nonReentrant
    {

        uint256 price = 0.06 ether;
        require(workflow == WorkflowStatus.Presale, "BSWC: Presale is not started yet!");
        require(ammount <= 10, "BSWC: Presale mint is one token only.");
        require(msg.value >= price * ammount, "INVALID_PRICE");
        require(hashMessage(msg.sender) == messageHash, "MESSAGE_INVALID");
        require(
            isValidData(messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        uint256 initial = 0;
        for (uint256 i = initial; i < ammount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function publicSaleMint(uint256 ammount) public payable nonReentrant {
        uint256 price = 0.12 ether;
        require(workflow != WorkflowStatus.SoldOut, "BSWC: SOLD OUT!");
        require(workflow == WorkflowStatus.Sale, "BSWC: public sale is not started yet");
        require(msg.value >= price * ammount, "BSWC: Insuficient funds");
        require(ammount <= 10, "BSWC: You can only mint up to 10 token at once!");
        for (uint256 i = 0; i < ammount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }


    // Before All.

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }
    function setUpBeforesale() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }
    function setUpSale() external onlyOwner {
        require(workflow == WorkflowStatus.Presale, "BSWC: Unauthorized Transaction");
        workflow = WorkflowStatus.Sale;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    function setSignerAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        signerAddress = _newAddress;
    }

  
     function withdrawAll() public payable onlyOwner {
        uint256 mainadress_balance = address(this).balance;
        require(payable(mainAddress).send(mainadress_balance));
    }
    function changeWallet(address _newwalladdress) external onlyOwner {
        mainAddress = _newwalladdress;
    }

    // FACTORY
  
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

}