pragma solidity ^0.8.0;
/**
* The Cash Cows contract was deployed by Ownerfy Inc. of Ownerfy.com
* https://ownerfy.com/cashcows
* Must have Chic-A-Dee EGGS to mint https://ownerfy.com/chicadees
* Visit Ownerfy.com for exclusive NFT drops or inquiries for your project.
*
* This contract is not a proxy. 
* This contract is not pausable.
* This contract is not lockable.
* This contract cannot be rug pulled.
* The URIs are not changeable after mint. 
* This contract uses IPFS 
* This contract puts SHA256 media hash into the Update event for permanent on-chain documentation
* The NFT Owners and only the NFT Owners have complete control over their NFTs 
*/

// SPDX-License-Identifier: UNLICENSED

// From base: 
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";

// interface IMILKInterface {
//     function balanceOf(address account, uint256 id) external view returns (uint);
// }

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract CashCows is Context, Ownable, ERC1155Burnable {

  using SafeMath for uint256;
  using Counters for Counters.Counter;

  address public eggsContract = 0xA16AB7dC3C7dc55aA0a59726144dcc4Bc30822c7;
  IERC20 eggsToken = IERC20(eggsContract);

  Counters.Counter private _tokenIdTracker;

  string public constant name = 'Cash Cows';
  string public constant symbol = 'CASHCOW';
  uint256 public price = 25000 * 10**18;
  uint256 public constant MAX_ELEMENTS = 3333;
  address public constant creatorAddress = 0x6c474099ad6d9Af49201a38b9842111d4ACd10BC;
  string public baseTokenURI;
  bool public placeHolder = true;

  uint256 private _royaltyBps = 500;
  address payable private _royaltyRecipient;

  bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;


  event Sale(address indexed sender, uint256 count, uint256 paid, uint256 price);
  event UpdateRoyalty(address indexed _address, uint256 _bps);


    /**
     * deploys the contract.
     */
    constructor(string memory _uri) payable ERC1155(_uri) {
      _royaltyRecipient = payable(msg.sender);
      baseTokenURI = _uri;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }


    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        
        _;
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }


    // This function is monitored by an external process which completes the minting
    // * Must have Chic-A-Dee EGGS to mint https://ownerfy.com/chicadees
    // * Must approve your Chic-A-Dees EGGS to spend by this contract to mint
    function mint(uint256 _count) public saleIsOpen {
        uint256 total = _totalSupply();
        uint256 eggCost = price.mul(_count);
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");

        require(eggCost <= _eggBalance(), "Must have more than or equal to EGGS cost");
        bool sent = eggsToken.transferFrom(msg.sender, address(this), eggCost);
        require(sent, "Token transfer failed");

        Sale(msg.sender, _count, eggCost, price);

        for (uint256 i = 0; i < _count; i++) {
            _mint(msg.sender, _tokenIdTracker.current(), 1, '');
            _tokenIdTracker.increment(); 
        }
    }


    // Set price
    function setPrice(uint256 _price) public onlyOwner{
        price = _price;
    }

    /**
     * @dev Checks `balance` eggs of sender.
     *
     */
    function _eggBalance() internal virtual returns(uint256 balance){

       return eggsToken.balanceOf(msg.sender);

    }


    // Function to withdraw all Ether and tokens from this contract.
    function withdraw() public onlyOwner{
        uint amount = address(this).balance;
        uint eggBalance = eggsToken.balanceOf(address(this));
        bool sent = eggsToken.transfer(msg.sender, eggBalance);

        require(sent, "Token transfer failed");
        if(amount > 0){
          (bool success, ) = _msgSender().call{value: amount}("");
          require(success, "Failed to send Ether");
        }
        
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setEggsContract(address _contract) public onlyOwner {
        eggsContract = _contract;
    }

    function setPlaceHolder(bool isOn) public onlyOwner {
        placeHolder = isOn;
    }


    function uri(uint256 _id) public view virtual override returns (string memory) {
        if(placeHolder) {
          return baseTokenURI;
        } else {
          return string(abi.encodePacked(baseTokenURI, uint2str(_id), ".json"));
        }
    }


    /**
    * @dev Update royalties
    */
    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
        emit UpdateRoyalty(recipient, bps);
    }

    /**
      * ROYALTY FUNCTIONS
      */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
               || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

     function uint2str(
      uint256 _i
    )
      internal
      pure
      returns (string memory str)
    {
      if (_i == 0)
      {
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0)
      {
        length++;
        j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0)
      {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
    }

}