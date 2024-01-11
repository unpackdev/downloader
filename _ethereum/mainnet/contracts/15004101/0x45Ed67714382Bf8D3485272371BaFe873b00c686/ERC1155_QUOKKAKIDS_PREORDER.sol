// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC1155.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

contract ERC1155_QUOKKAKIDS_PREORDER is ERC1155, Ownable {
    using Address for address;
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant DOUBLE_TICKET = 2;
    uint256 public constant TRIPLE_TICKET = 3;

    string public _baseTokenURI;
    IERC721 public tribeQuokkaGenesisToken;
    uint public price = 100000000000000000;

    mapping(address => bool) public burner;
    mapping(uint => uint) public totalSupply;

    uint public totalTokenLimit = 2500;
    uint public walletLimit = 5;
    bool public refundsAllowed = true;
    bool public mintAllowed = true;

    address public whitelistSigner = 0x3dF6f92097B349f30d31315a7453821f14998f3E;

    address payable public payout = payable(0x6A4813082c2F6598b01698B222c5b1414Fe77eF6);

    bytes32 constant DOMAIN_SEPERATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("Signer NFT Distributor"),
        keccak256("1"),
        uint256(1),
        address(0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC)
    ));

    bytes32 constant ENTRY_TYPEHASH = keccak256("Entry(address wallet)");

    constructor() ERC1155("https://game.example/api/item/{id}.json") {
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
      _setURI(baseURI);
    }

    function setPrice(uint _price) public onlyOwner {
      price = _price;
    }
    function setRefundAllowed(bool _val) public onlyOwner {
      refundsAllowed = _val;
    }

    function setMintAllowed(bool _val) public onlyOwner {
      mintAllowed = _val;
    }

    function setTotalTokenLimit(uint _total) public onlyOwner {
      totalTokenLimit = _total;
    }

    function setWalletLimit(uint _limit) public onlyOwner {
      walletLimit = _limit;
    }

    function setSignerAddress(address signer) public onlyOwner {
        whitelistSigner = signer;
    }
    
    function setBurner(address addr, bool active) public onlyOwner {
      // there's a burner on the network
      burner[addr] = active;
    }

    function setPayout(address addr) public onlyOwner {
      payout = payable(addr);
    }

    function release(uint amount) public {
      uint ourBalance = address(this).balance;
      require(ourBalance >= amount, "Must have enough balance to send");
      payout.transfer(amount);
    }

    function setGenesisContract(address tqGenesisContract) public onlyOwner {
      tribeQuokkaGenesisToken = IERC721(tqGenesisContract);
    }

    function mint(uint doubles, uint triples, bytes memory signature) public payable {
      require(mintAllowed, "Minting period has ended");
      uint doublesBalance = balanceOf(_msgSender(), DOUBLE_TICKET);
      uint triplesBalance = balanceOf(_msgSender(), TRIPLE_TICKET);
      uint newUserBalance = doubles + triples + doublesBalance + triplesBalance;
      require(walletLimit >= newUserBalance, "Can't exceed the wallet limit");
      require(totalTokenLimit >= doubles + triples + totalSupply[DOUBLE_TICKET] + totalSupply[TRIPLE_TICKET], "Can't exceed the wallet limit");
      require((doubles + triples) * price >= msg.value, "Not enough ETH sent");

      bytes32 digestreal = keccak256(abi.encodePacked(
          msg.sender
      ));

      address claimSigner = digestreal.toEthSignedMessageHash().recover(signature);
      require(claimSigner == whitelistSigner, "Invalid Message Signer.");

      if (doubles > 0) {
        totalSupply[DOUBLE_TICKET] += doubles;
        _mint(msg.sender, DOUBLE_TICKET, doubles, "");
      }
      if (triples > 0) {
        // verify triples held
        // verify quokkas held
        require(tribeQuokkaGenesisToken.balanceOf(_msgSender()) >= (triplesBalance + triples), "Not enough Genesis tokens");
        totalSupply[TRIPLE_TICKET] += triples;
        _mint(msg.sender, TRIPLE_TICKET, triples, "");
      }
    }
    function ownerMint(address account, uint doubles, uint triples) public payable onlyOwner {

      if (doubles > 0) {
        totalSupply[DOUBLE_TICKET] += doubles;
        _mint(account, DOUBLE_TICKET, doubles, "");
      }
      if (triples > 0) {
        totalSupply[TRIPLE_TICKET] += triples;
        _mint(account, TRIPLE_TICKET, triples, "");
      }
    }

    function refund(uint doublesToReturn, uint triplesToReturn) public {
      require(refundsAllowed, "Refund period has ended");
      require(doublesToReturn > 0 || triplesToReturn > 0, "You must refund something");
      if (doublesToReturn > 0) {
       require(balanceOf(_msgSender(), DOUBLE_TICKET) >= doublesToReturn, "Need enough doubles to return");
        totalSupply[DOUBLE_TICKET] -= doublesToReturn;
       _burn(_msgSender(), DOUBLE_TICKET, doublesToReturn);
      }
      if (triplesToReturn > 0) {
       require(balanceOf(_msgSender(), TRIPLE_TICKET) >= triplesToReturn, "Need enough triples to return");
        totalSupply[TRIPLE_TICKET] -= triplesToReturn;
       _burn(_msgSender(), TRIPLE_TICKET, triplesToReturn);
      }

      uint refundAmount = price * (doublesToReturn + triplesToReturn);
      payable(_msgSender()).transfer(refundAmount);
    }

    function burn(
      address from,
      uint256 id,
      uint256 amount) public {
      require(burner[_msgSender()], "ERC1155_QUOKKAKIDS_PREORDER: must have burner role to burn");
      totalSupply[id] -= amount;
      _burn(from, id, amount);
    }

    function deposit() payable public {
        // nothing to do!
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}