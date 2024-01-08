// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Base64.sol";

// Run It Wild + PrimeFlare 2021
// Bin Kingz

contract BKToken is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using SafeMath for uint256;

  struct Kingz {
    string name;
    uint16[8] traits;
  }

  // // traits
  string[12] private BACKGROUND = ["Gold", "Blue Orange Tags", "Blue Yellow Tags" , "Green Red Tags" , "White Purple Tags", "Yellow Purple Tags", "Blue", "Green", "Sunset", "Teal", "White", "Yellow"];
  string[6] private KINGZ = ["Gold King", "Blue King", "Kookaburra King", "Pink King", "Tutti Fruity King", "King"];
  string[21] private HATS = ["None", "Crown", "Skullet", "Corkhat", "Black Graffiti Crown", "Hard Hat", "Lad Hat", "Mullet", "Pink Cap", "Wally Hat", "Dundee Hat", "Fitness Hat", "Flap Hat", "Golf Visor", "Akubra", "Backwards Hat", "Balaclava", "Beanie Long Hair", "Byron Hat", "Capper Mullet", "Ranga"];
  string[17] private CHEST = ["None", "Dollar Chains", "Orange Hi Vis", "Amythyst Neck", "Aussie Bow", "Blue Tie", "Black Bum Bag", "Blue Bum Bag", "Designer Bag", "Cross Chain", "Fashion Bag", "Footy Scarf", "Yellow Hi Vis", "Red Tie", "Satchel Bag", "Stacked Chains", "Tattz"];
  string[15] private EYES = ["None", "Gold Thug Life", "Cyclops", "Dreamy Blues", "Aviators", "Edna Glasses", "Monocle", "Reading Glasses", "Round Glasses", "Smokey Eyes", "Black Speed Dealers", "Green Speed Dealers", "Pink Speed Dealers", "Thug Life", "Fashion Sunglasses"];
  string[14] private MOUTH = ["None", "Grill", "Gold Joint", "Nang", "Crack Pipe", "Fancy Cigarette", "Joint", "Lippy", "Old Man Pipe", "Vape", "Stogie", "Dart", "Durry Muncher", "Menthol"];
  string[14] private SHOES = ["None", "Designer Sneaks", "Fish Feet", "Maxies", "Blue TNs", "Boat Shoes", "Boots", "Crocs", "Office Shoes", "Orange TNs", "Steel Toe Cap Boots", "Stilettos", "Volleys", "Socks and Slides"];
  string[40] private ITEMS = ["None", "Chicken Nugget", "Galve", "Gold Box Cutter", "WRX", "Ironlak", "AFL Football", "Box Cutter", "Briefcase", "Bubbles", "Choccie Milk", "Dirt Bike", "Esky", "Bag", "Gatorbeug", "Golf Club", "Goon Bag", "Hair Straightener", "Jacuzzi", "Kebab", "Kombucha", "League Football", "Long Neck Beer Bottle", "Office Bin", "Pink Mitsu", "Pizza", "Protein Shake", "Rollie", "Salad", "Servo Pie", "Silverspoon", "Lambo", "Spraycan", "Tinnie Boat", "Ute", "Wheelie Bin Full", "Wheelie Bin Closed", "Yoga Mat", "Takeaway Coffee", "Devon Tomato Sauce Sambo"];

  // constants
  uint256 public constant BUY_PRICE = 0.069 ether;
  uint16 public constant MAX_SUPPLY = 6841;
  uint16 public constant MAX_SUPPLY_TEAM_HEAD = 6879;
  uint16 public constant MAX_SUPPLY_TEAM_TAIL = 6969;
  uint8 public constant MAX_PER_ACCOUNT = 25;
  uint16 public constant MAX_SUPPLY_WHITELIST = 5000;

  // variables
  bool public presalesActive = false;
  bool public salesActive = false;
  bool public revealed = false;
  string public baseURI;
  string private imageURI;

  mapping (uint16 => Kingz) private kings;
  mapping (uint16 => bool) private SpecialList;

  address private signer = 0x2c4fcCF94F6b55178355a6afACB4be3AAFdEc4e7;

  address payable private ownerA = payable(0x4F93192bc3527421fca0D9f8DBFeAd709934b978);
  address payable private ownerB = payable(0x7396273f2D08aBf6F2050C64959c355Be41eD94f);
  address payable private ownerC = payable(0x20ab0b9E0dcf895BEc390b0DE42e53aC2Fba80de);

  mapping (uint16 => uint16) private randoms;
  uint16 public boundary = MAX_SUPPLY;

  mapping(address => bool) private whitelist;
  uint16 public totalWhitelistClaim = 0;

  WhitelistContract public WHITELIST_CONTRACT_B;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B1 = 1;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B2 = 2;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B3 = 10003;
  uint16 public constant WHITELIST_CONTRACT_TOKEN_B4 = 10004;

  receive() external payable onlyOwner {}

  constructor() ERC721('BKToken', 'BKT') {
    WHITELIST_CONTRACT_B = WhitelistContract(0x10DaA9f4c0F985430fdE4959adB2c791ef2CCF83);
  }

  function toggleActive() external onlyOwner {
    salesActive = !salesActive;
  }

  function toggleReveal() external onlyOwner {
    revealed = !revealed;
  }

  function togglePresale() external onlyOwner {
    presalesActive = !presalesActive;
  }

  function setTokenURI(string calldata _uri, string calldata _imageUri) external onlyOwner {
    baseURI = _uri;
    imageURI = _imageUri;
  }

  function setSignerAddress(address _siger) external onlyOwner {
    signer = _siger;
  }

  function eligiblePresale() public view returns(bool) {
    return WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B1) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B2) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B3) > 0 ||
      WHITELIST_CONTRACT_B.balanceOf(msg.sender, WHITELIST_CONTRACT_TOKEN_B4) > 0 ||
      whitelist[msg.sender];
  }

  function setTokenInfo(uint16 _tokenId, string calldata _name, uint16[8] calldata _traits, bytes calldata signature) external {
    require(_exists(_tokenId), "URI query for non existent token");
    require(ownerOf(_tokenId) == msg.sender, "Must owner of this token.");
    require(!SpecialList[_tokenId], "This token can not be modified");
    require(validateName(_name), "Name: Minimum 3 and maximum 12 characters.");
    require(_traits[0] < BACKGROUND.length, "Attribute 0 out of range.");
    require(_traits[1] < KINGZ.length, "Attribute 1 out of range.");
    require(_traits[2] < HATS.length, "Attribute 2 out of range.");
    require(_traits[3] < CHEST.length, "Attribute 3 out of range.");
    require(_traits[4] < EYES.length, "Attribute 4 out of range.");
    require(_traits[5] < MOUTH.length, "Attribute 5 out of range.");
    require(_traits[6] < SHOES.length, "Attribute 6 out of range.");
    require(_traits[7] < ITEMS.length, "Attribute 7 out of range.");
    require(verifyMessage(_traits, signature), "Set token traits not allowed.");

    kings[_tokenId].name = string(abi.encodePacked(_name, ' #', Strings.toString(_tokenId)));
    kings[_tokenId].traits = _traits;
  }

  function addSpecialTokens(uint16[] calldata _tokenIds) external onlyOwner {
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      if (_exists(_tokenIds[i])) {
        SpecialList[_tokenIds[i]] = true;
      }
    }
  }

  function setTokenName(uint16 _tokenId, string calldata _name) external onlyOwner {
    kings[_tokenId].name = _name;
  }

  function addWhitelist(address[] calldata _accounts, bool _status) external onlyOwner {
    for(uint256 i = 0; i < _accounts.length; i++) {
      whitelist[_accounts[i]] = _status;
    }
  }

  function whitelistClaim(uint8 _amount) external payable {
    require(presalesActive, "Claim is not active");
    require(eligiblePresale(), "Claim: Not allowed.");
    require(tx.origin == msg.sender, "Claim Can not be made from a contract");
    require(balanceOf(msg.sender) + _amount <= MAX_PER_ACCOUNT, "Claim: Can not claim that many.");
    require(msg.value >= BUY_PRICE * _amount, "Claim: Ether value incorrect.");
    require(totalWhitelistClaim + _amount <= MAX_SUPPLY_WHITELIST, "Claim: All whitelist tokens have sold out");
    require(boundary >= _amount, "Claim: All tokens are sold out.");

    for(uint256 i = 0; i < _amount; i++){
      uint16 index = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender, totalSupply(), address(this)))) % boundary) + 1;
      uint16 tokenId = randoms[index] > 0 ? randoms[index] : index;
      randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
      boundary = boundary - 1;

      _safeMint(msg.sender, tokenId);
      totalWhitelistClaim = totalWhitelistClaim + 1;
    }
  }

  function claim(uint8 _amount) external payable {
    require(salesActive, "Claim is not active");
    require(tx.origin == msg.sender, "Claim cannot be made from a contract");
    require(boundary >= _amount, "Claim: All tokens are sold out.");
    require(msg.value >= BUY_PRICE * _amount, "Claim: Ether value incorrect.");
    require(balanceOf(msg.sender) + _amount <= MAX_PER_ACCOUNT, "Claim: Can not claim that many.");

    for(uint256 i = 0; i < _amount; i++){
      uint16 index = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, msg.sender, totalSupply(), address(this)))) % boundary) + 1;
      uint16 tokenId = randoms[index] > 0 ? randoms[index] : index;
      randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
      boundary = boundary - 1;

      _safeMint(msg.sender, tokenId);
    }
  }

  function teamClaimA() external onlyOwner {
    for(uint256 i = MAX_SUPPLY + 1; i < MAX_SUPPLY_TEAM_HEAD; i++){
      _safeMint(ownerB, i);
    }
  }

  function teamClaimB() external onlyOwner {
    for(uint256 i = MAX_SUPPLY_TEAM_HEAD; i < MAX_SUPPLY_TEAM_TAIL; i++){
      _safeMint(ownerA, i);
    }
  }

  function withdraw() public onlyOwner {
    uint balanceA = address(this).balance.mul(500).div(1000);
    uint balanceB = address(this).balance.mul(400).div(1000);
    uint balanceC = address(this).balance.sub(balanceA).sub(balanceB);

    ownerA.transfer(balanceA);
    ownerB.transfer(balanceB);
    ownerC.transfer(balanceC);
  }

  function getAttributes(uint16[8] memory attributes) private view returns (string memory){
    string memory firstHalf = string(abi.encodePacked(
      '[{"trait_type":"Background","value":"',BACKGROUND[attributes[0]],'"},',
      '{"trait_type":"Kingz","value":"',KINGZ[attributes[1]], '"},',
      '{"trait_type":"Hats","value":"',HATS[attributes[2]], '"},',
      '{"trait_type":"Chest","value":"',CHEST[attributes[3]], '"},'
    ));
    string memory secondHalf = string(abi.encodePacked(
      '{"trait_type":"Eyes","value":"',EYES[attributes[4]],'"},',
      '{"trait_type":"Mouth","value":"', MOUTH[attributes[5]], '"},',
      '{"trait_type":"Shoes","value":"', SHOES[attributes[6]], '"},',
      '{"trait_type":"Items","value":"', ITEMS[attributes[7]], '"}]'
    ));

    return string(abi.encodePacked(firstHalf, secondHalf));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for non existent token");
    if (!revealed) {
      return "ipfs://QmZPWE1KSq64r7ZqDE38wuYshHu9XKX5VAavsfH8firivL";
    }
    if (isBlank(kings[uint16(_tokenId)].name)) {
      return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
    Kingz memory tokenInfo = kings[uint16(_tokenId)];
    bytes memory response = bytes(abi.encodePacked(
      '{',
      '"image":"', imageURI, Strings.toString(_tokenId), '.jpg', '"', ',',
      '"name":"', tokenInfo.name, '"', ',',
      '"external_url":"https://binkingz.com"', ',',
      '"description":"Bin Kingz by Scott Marsh are 6,969 completely unique NFT bin chickens, each with their own unique traits, rarities and personalities. Holding one of these will give you exclusive access to events, wearables and giveaways."', ',',
      '"attributes":', getAttributes(tokenInfo.traits),
      '}'
    ));
    return string(abi.encodePacked("data:application/json;charset=utf-8;base64,", Base64.encode(response)));
  }

  function isBlank(string memory _string) private pure returns (bool) {
    return bytes(_string).length == 0;
  }

  function validateName(string calldata _string) private pure returns (bool) {
    return bytes(_string).length >= 3 && bytes(_string).length <= 12;
  }

  function isSpecial(uint16 _tokenId) external view returns (bool) {
    return _exists(_tokenId) && SpecialList[_tokenId];
  }

  function splitSignature(bytes memory sig) private pure returns (uint8, bytes32, bytes32) {
    require(sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    return (v, r, s);
  }

  function verifyMessage(uint16[8] calldata _traits, bytes calldata signature) public view returns (bool) {
    string memory message = string(abi.encodePacked(
      Strings.toString(_traits[0]), '_',
      Strings.toString(_traits[1]), '_',
      Strings.toString(_traits[2]), '_',
      Strings.toString(_traits[3]), '_',
      Strings.toString(_traits[4]), '_',
      Strings.toString(_traits[5]), '_',
      Strings.toString(_traits[6]), '_',
      Strings.toString(_traits[7])
    ));

    uint256 _messageLen = bytes(message).length;
    bytes32 _ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(_messageLen), message)); // number be length message
    (uint8 _v, bytes32 _r, bytes32 _s) = splitSignature(signature);
    return (ecrecover(_ethSignedMessageHash, _v, _r, _s) == signer);
  }
}

interface WhitelistContract {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}
