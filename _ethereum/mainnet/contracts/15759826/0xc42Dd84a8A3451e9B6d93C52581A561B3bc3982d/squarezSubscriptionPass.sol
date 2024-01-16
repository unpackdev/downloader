// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
// Subscription
// set approve for all to another contract
// Whitelist sale
contract SquarezSubscriptionPass is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;
    uint256 public state=0;
    uint256 public collectionSize=420;
    uint256 public whitelistMintMaxSize=380; // 40 for team, 111 for genesis.
    // address public signerAddress = 0x8083ddC308eE77E72DfaCD0F38595FB7F16916Ac;
    address public signerAddress = 0xbE56195Fb8dA052Cad59d796CBC8c0F89fc37c33;
    address public genesisAddress = 0xBADC22968EeE7926C418639bF5FCCF0f1eDeA4E9;
    mapping(address => uint) public genesisMintCount; // Address to genesis mint count
    mapping(uint256 => bool) public genesisMinted; // tokenId -> if minted
    // Subscription
    mapping(address => mapping(uint256 => uint256)) public expiryTime; // tokenId -> (plan -> time)
    mapping(uint256 => uint256) public planTime; // plan 1/2/3 -> timeDelta
    mapping(uint256 => uint256) public planPrice; // plan 1/2/3 -> price
    mapping(uint256 => string) public planTrait;
    uint256 public maxPlan=1;
    // MarketPlace
    mapping(address => bool) public marketPlace;
    // Art
    // Random seeds: tokenId -> random number
    uint256 public randomSeed;

  constructor() ERC721A("SquarezPass", "SP") {
    planTrait[1]="Ethereum classic signals";
    planTime[1]=30;
    planPrice[1]=0.02 ether;
    marketPlace[0x1E0049783F008A0085193E00003D00cd54003c71]=true; // opensea
    marketPlace[0xF849de01B080aDC3A814FaBE1E2087475cF2E354]=true; // x2y2
  }

  // Change state: 0 (default)
  // 1 : Genesis mint, 2 : Whitelist mint with subscription, 3 : Whitelist flipper/art collector mint.
  function changeState(uint256 _state) external onlyOwner{
      state = _state;
  }

  function setGenesisAddress(address _addr) external onlyOwner{
      genesisAddress = _addr;
  }

  // Genesis pass mint (phase1)
  function genesisMintP1(address to, uint256[] calldata token_ids) external nonReentrant{
      require (state == 1, "Not genesis mint phase");
      //uint tokenId = totalSupply();
      uint count=0;
      ERC721A squarezGenesis = ERC721A(genesisAddress);
      for (uint i=0; i<token_ids.length; i++){
          if (i < squarezGenesis.totalSupply()){
              if ((squarezGenesis.ownerOf(token_ids[i]) == to) && (!genesisMinted[token_ids[i]])){
                  genesisMinted[token_ids[i]] = true;
                  count += 1;
              }
          }
      }
      genesisMintCount[to] += count;
      if (count > 0) _safeMint(to, count);
  }
  // Whitelist mint (phase2, pay subscription for the first month)
  function whiteListMintP2(address to, bytes calldata _signature)
    external
    payable
    nonReentrant
  {
    uint tokenId = totalSupply();
    require (state == 2, "Not whitelist mint phase");
    require(tokenId + 1 <= whitelistMintMaxSize, "Reached max supply");
    require(numberMinted(to) < 1, "Max per wallet: 1");
    require(isAuthorized(to, _signature), "Signature is invalid");
    require(tx.origin == msg.sender, "Bot not allowed");
    require(msg.value >= 0.015 ether, "Need 0.015 ether for the first month subscription");
    _safeMint(to, 1);
    expiryTime[to][1] = block.timestamp + 37 days;
    payable(owner()).transfer(msg.value);
  }
  // Whitelist mint (phase3, no subscription)
  function whiteListMintP3(address to, bytes calldata _signature)
    external
    nonReentrant
  {
    uint tokenId = totalSupply();
    require (state == 3, "Not whitelist mint phase");
    require(tokenId + 1 <= whitelistMintMaxSize, "Reached max supply");
    require(numberMinted(to) < 1, "Max per wallet: 1");
    require(isAuthorized(to, _signature), "Signature is invalid");
    require(tx.origin == msg.sender, "Bot not allowed");
    _safeMint(to, 1);
    //expiryTime[to][1] = block.timestamp + 7 days;
  }
  // Whitelist verification
  function setSignerAddress(address addr) external onlyOwner{
    signerAddress = addr;
  }
  function isAuthorized(address sender, bytes calldata signature) public view returns (bool){
      return signerAddress == keccak256(abi.encodePacked(sender)).recover(signature);
  }
  // Dev mint
  function devMint(uint256 quantity) external onlyOwner{
      uint tokenId = totalSupply();
      require(tokenId + quantity <= collectionSize, "Reached max supply");
      _safeMint(msg.sender, quantity);
  }

  // Subscription
  function setMaxPlan(uint _maxPlan) external onlyOwner {
      maxPlan = _maxPlan;
  }

  function renewSubscription(uint256 _tokenId, uint256 plan) public payable nonReentrant{
    require(msg.value >= planPrice[plan], "Not enough money for this subscription plan");
    require(plan <= maxPlan, "Plan not available");
    payable(owner()).transfer(msg.value);
    address holder=ownerOf(_tokenId);
    if (block.timestamp > expiryTime[holder][plan]) {
      expiryTime[holder][plan] = block.timestamp + (planTime[plan] * 1 days);
    }
    else{
      expiryTime[holder][plan] += planTime[plan] * 1 days;
    }
  }

  function addSubscriptionPlan(uint256 plan, uint256 nb_days, uint256 price, string calldata trait) external onlyOwner {
    planTime[plan] = nb_days;
    planPrice[plan] = price;
    planTrait[plan] = trait;
    maxPlan = plan >= maxPlan? plan : maxPlan;
  }

  
  // Metadata
  string public baseURI="https://pinner-studio.xyz/metadata/";

  function setBaseURI(string calldata _baseURI) external onlyOwner {
      baseURI = _baseURI;
  }

  function property(uint256 tokenId) public view returns (string memory){
      string memory _property = "";
      address holder = ownerOf(tokenId);
      for (uint i=1; i < maxPlan; i++){
          _property = string(abi.encodePacked(_property, '{"display_type": "date", "trait_type":"', planTrait[i], '","value":', Strings.toString(expiryTime[holder][i]), '},'));
      }
      _property = string(abi.encodePacked(_property, '{"display_type": "date", "trait_type":"', planTrait[maxPlan], '","value":', Strings.toString(expiryTime[holder][maxPlan]), '}'));
      return _property;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory){
      string memory _name = string(abi.encodePacked("Squarez #", Strings.toString(tokenId)));
      string memory _description = "Squarez pass - Your subscription pass to quantitative signals.";
      string memory _properties = property(tokenId);
      return string(
          abi.encodePacked(
              "data:application/json;base64,",
              Base64.encode(
                  bytes(
                      abi.encodePacked(
                          '{"name":"', _name,
                          '", "description": "', _description,
                          '", "attributes": [', _properties,
                          '], "image":"', baseURI, Strings.toString(tokenId), '.png", '
                          '"animated_url":"', baseURI, Strings.toString(tokenId), '.html"}'
                      )
                  )
              )
          )
      );
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner) - genesisMintCount[owner];
  }
  function swapMarketPlace(address operator) external onlyOwner {
      marketPlace[operator] = !marketPlace[operator];
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
      if (marketPlace[operator]) return true;
      return super.isApprovedForAll(owner, operator);
  }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
