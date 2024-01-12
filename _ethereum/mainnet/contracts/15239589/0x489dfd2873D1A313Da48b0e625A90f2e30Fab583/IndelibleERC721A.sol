
  // SPDX-License-Identifier: MIT
  pragma solidity ^0.8.4;
  
  import "./ERC721A.sol";
  import "./ReentrancyGuard.sol";
  import "./Ownable.sol";
  import "./Base64.sol";
  import "./Address.sol";
  import "./SSTORE2.sol";
  import "./DynamicBuffer.sol";
  import "./HelperLib.sol";
  
  contract IndelibleERC721A is ERC721A, ReentrancyGuard, Ownable {
      using HelperLib for uint256;
      using DynamicBuffer for bytes;

      struct TraitDTO {
          string name;
          string mimetype;
          bytes data;
      }
      
      struct Trait {
          string name;
          string mimetype;
      }

      struct ContractData {
          string name;
          string description;
          string image;
          string banner;
          string website;
          uint256 royalties;
          string royaltiesRecipient;
      }
  
      mapping(uint256 => string) internal _tokenIdToHash;
      mapping(uint256 => address[]) internal _traitDataPointers;
      mapping(uint256 => mapping(uint256 => Trait)) internal _traitDetails;
      mapping(uint256 => bool) internal _renderTokenOffChain;
  
      uint256 SEED_NONCE = 0;
      uint256 private constant DEVELOPER_FEE = 250; // of 10,000 = 2.5%
      uint256 private constant NUM_LAYERS = 7;
      uint256[][NUM_LAYERS] private TIERS;
      string[] private LAYER_NAMES = [unicode"Nose", unicode"Mouth", unicode"Ears", unicode"Neck", unicode"Shades", unicode"Hats", unicode"Background"];
      bool private shouldWrapSVG = true;
      uint256 public constant maxSupply = 4128;
      uint256 public maxPerAddress = 100;
      uint256 public mintPrice = 0.010 ether;
      string public baseURI = "";
      bool public isMintingPaused = true;
      ContractData public contractData = ContractData(unicode"Still Life with Punk Attributes", unicode"Still Life with Punk Attributes", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/2a1f260b-cccb-4d5f-8168-1b70735e80f2", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/2a1f260b-cccb-4d5f-8168-1b70735e80f2", "www.leandercapuozzo.com/still-life-with-punk-attributes", 0, "0xE3edE2Fc1E9192d8B9D82B8dA35b711925bcF133");

      constructor() ERC721A(unicode"Still Life with Punk Attributes", unicode"punkstlfe") {
        TIERS[0] = [212,3916];
TIERS[1] = [175,272,317,961,2403];
TIERS[2] = [1459,2669];
TIERS[3] = [48,156,169,3755];
TIERS[4] = [286,332,378,461,502,527,535,535,572];
TIERS[5] = [44,54,55,86,95,115,142,159,178,186,203,254,300,351,406,419,481,600];
TIERS[6] = [4128];
      }
  
      modifier whenPublicMintActive() {
          require(isPublicMintActive(), "Public sale not open");
          _;
      }
  
      function rarityGen(uint256 _randinput, uint256 _rarityTier)
          internal
          view
          returns (uint256)
      {
          uint256 currentLowerBound = 0;
          for (uint256 i = 0; i < TIERS[_rarityTier].length; i++) {
              uint256 thisPercentage = TIERS[_rarityTier][i];
              if (
                  _randinput >= currentLowerBound &&
                  _randinput < currentLowerBound + thisPercentage
              ) return i;
              currentLowerBound = currentLowerBound + thisPercentage;
          }
  
          revert();
      }
  
      function hash(
          uint256 _tokenId,
          address _account
      ) internal view returns (string memory) {
          // This will generate a NUM_LAYERS * 3 character string.
          bytes memory hashBytes = DynamicBuffer.allocate(NUM_LAYERS * 4);
  
          for (uint256 i = 0; i < NUM_LAYERS; i++) {
              uint256 _randinput = uint256(
                  uint256(
                      keccak256(
                          abi.encodePacked(
                              tx.gasprice,
                              block.number,
                              block.timestamp,
                              block.difficulty,
                              blockhash(block.number - 1),
                              _tokenId,
                              _account,
                              _tokenId + i
                          )
                      )
                  ) % maxSupply
              );

              uint256 rarity = rarityGen(_randinput, i);

              if (rarity < 10) {
                  hashBytes.appendSafe("00");
              } else if (rarity < 100) {
                  hashBytes.appendSafe("0");
              }
              if (rarity > 999) {
                  hashBytes.appendSafe("999");
              } else {
                  hashBytes.appendSafe(bytes(_toString(rarity)));
              }
          }
  
          return string(hashBytes);
      }
  
      function mint(uint256 _count) external payable nonReentrant whenPublicMintActive returns (uint256) {
          uint256 totalMinted = _totalMinted();
          require(_count > 0, "Invalid token count");
          require(totalMinted + _count <= maxSupply, "All tokens are gone");
          require(_count * mintPrice == msg.value, "Incorrect amount of ether sent");
          if (msg.sender != owner()) {
              require(balanceOf(msg.sender) + _count <= maxPerAddress, "Exceeded max mints allowed.");
          }
  
          for (uint256 i = 0; i < _count; i++) {
              _tokenIdToHash[totalMinted + i] = hash(totalMinted + i, msg.sender);
          }
  
          _mint(msg.sender, _count);
          return totalMinted;
      }
  
      function isPublicMintActive() public view returns (bool) {
          return _totalMinted() < maxSupply && isMintingPaused == false;
      }

      function hashToSVG(string memory _hash)
          public
          view
          returns (string memory)
      {
          uint256 thisTraitIndex;
          
          bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
          svgBytes.appendSafe('<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-image:url(');

          for (uint256 i = 0; i < NUM_LAYERS - 1; i++) {
              thisTraitIndex = HelperLib.parseInt(
                  HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
              );
              svgBytes.appendSafe(
                  abi.encodePacked(
                      "data:",
                      _traitDetails[i][thisTraitIndex].mimetype,
                      ";base64,",
                      Base64.encode(SSTORE2.read(_traitDataPointers[i][thisTraitIndex])),
                      "),url("
                  )
              );
          }

          thisTraitIndex = HelperLib.parseInt(
              HelperLib._substring(_hash, (NUM_LAYERS * 3) - 3, NUM_LAYERS * 3)
          );

          svgBytes.appendSafe(
              abi.encodePacked(
                  "data:",
                  _traitDetails[NUM_LAYERS - 1][thisTraitIndex].mimetype,
                  ";base64,",
                  Base64.encode(SSTORE2.read(_traitDataPointers[NUM_LAYERS - 1][thisTraitIndex])),
                  ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
              )
          );

          return string(
              abi.encodePacked(
                  "data:image/svg+xml;base64,",
                  Base64.encode(svgBytes)
              )
          );
      }

      function hashToMetadata(string memory _hash)
          public
          view
          returns (string memory)
      {
          bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
          metadataBytes.appendSafe("[");

          for (uint256 i = 0; i < NUM_LAYERS; i++) {
              uint256 thisTraitIndex = HelperLib.parseInt(
                  HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
              );
              metadataBytes.appendSafe(
                  abi.encodePacked(
                      '{"trait_type":"',
                      LAYER_NAMES[i],
                      '","value":"',
                      _traitDetails[i][thisTraitIndex].name,
                      '"}'
                  )
              );
              
              if (i == NUM_LAYERS - 1) {
                  metadataBytes.appendSafe("]");
              } else {
                  metadataBytes.appendSafe(",");
              }
          }

          return string(metadataBytes);
      }
  
      function tokenURI(uint256 _tokenId)
          public
          view
          override
          returns (string memory)
      {
          require(_exists(_tokenId), "Invalid token");
          require(_traitDataPointers[0].length > 0,  "Traits have not been added");

          string memory tokenHash = _tokenIdToHash[_tokenId];

          bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);
          jsonBytes.appendSafe(unicode"{\"name\":\"Still Life with Punk Attributes #");

          jsonBytes.appendSafe(
              abi.encodePacked(
                  _toString(_tokenId),
                  "\",\"description\":\"",
                  contractData.description,
                  "\","
              )
          );

          if (bytes(baseURI).length > 0 && _renderTokenOffChain[_tokenId]) {
              jsonBytes.appendSafe(
                  abi.encodePacked(
                      '"image":"',
                      baseURI,
                      _toString(_tokenId),
                      "?dna=",
                      tokenHash,
                      '&network=mainnet",'
                  )
              );
          } else {
            string memory svgCode = "";
            if (shouldWrapSVG) {
                string memory svgString = hashToSVG(tokenHash);
                svgCode = string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                svgString,
                                '"></image></svg>'
                            )
                        )
                    )
                );
                jsonBytes.appendSafe(
                    abi.encodePacked(
                        '"svg_image_data":"',
                        svgString,
                        '",'
                    )
                );
            } else {
                svgCode = hashToSVG(tokenHash);
            }

            jsonBytes.appendSafe(
                abi.encodePacked(
                    '"image_data":"',
                    svgCode,
                    '",'
                )
            );
          }

          jsonBytes.appendSafe(
              abi.encodePacked(
                  '"attributes":',
                  hashToMetadata(tokenHash),
                  "}"
              )
          );

          return string(
              abi.encodePacked(
                  "data:application/json;base64,",
                  Base64.encode(jsonBytes)
              )
          );
      }

      function contractURI()
          public
          view
          returns (string memory)
      {
          return string(
              abi.encodePacked(
                  "data:application/json;base64,",
                  Base64.encode(
                      abi.encodePacked(
                          '{"name":"',
                          contractData.name,
                          '","description":"',
                          contractData.description,
                          '","image":"',
                          contractData.image,
                          '","banner":"',
                          contractData.banner,
                          '","external_link":"',
                          contractData.website,
                          '","seller_fee_basis_points":',
                          _toString(contractData.royalties),
                          ',"fee_recipient":"',
                          contractData.royaltiesRecipient,
                          '"}'
                      )
                  )
              )
          );
      }
  
      function tokenIdToHash(uint256 _tokenId)
          public
          view
          returns (string memory)
      {
          return _tokenIdToHash[_tokenId];
      }

      function tokenIdToSVG(uint256 _tokenId)
          public
          view
          returns (string memory)
      {
          return hashToSVG(tokenIdToHash(_tokenId));
      }
  
      function traitDetails(uint256 _layerIndex, uint256 _traitIndex)
          public
          view
          returns (Trait memory)
      {
          return _traitDetails[_layerIndex][_traitIndex];
      }
  
      function traitData(uint256 _layerIndex, uint256 _traitIndex)
          public
          view
          returns (string memory)
      {
          return string(SSTORE2.read(_traitDataPointers[_layerIndex][_traitIndex]));
      }
  
      function addLayer(uint256 _layerIndex, TraitDTO[] memory traits)
          public
          onlyOwner
      {
          require(TIERS[_layerIndex].length == traits.length, "Traits size does not match tiers for this index");
          address[] memory dataPointers = new address[](traits.length);
          for (uint256 i = 0; i < traits.length; i++) {
              dataPointers[i] = SSTORE2.write(traits[i].data);
              _traitDetails[_layerIndex][i] = Trait(traits[i].name, traits[i].mimetype);
          }
          _traitDataPointers[_layerIndex] = dataPointers;
          return;
      }
  
      function addTrait(uint256 _layerIndex, uint256 _traitIndex, TraitDTO memory trait)
          public
          onlyOwner
      {
          _traitDetails[_layerIndex][_traitIndex] = Trait(trait.name, trait.mimetype);
          address[] memory dataPointers = _traitDataPointers[_layerIndex];
          dataPointers[_traitIndex] = SSTORE2.write(trait.data);
          _traitDataPointers[_layerIndex] = dataPointers;
          return;
      }
      
      function changeContractData(ContractData memory _contractData) external onlyOwner {
          contractData = _contractData;
      }

      function changeMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
          maxPerAddress = _maxPerAddress;
      }
  
      function changeBaseURI(string memory _baseURI) external onlyOwner {
          baseURI = _baseURI;
      }

      function changeRenderOfTokenId(uint256 _tokenId, bool _renderOffChain) external {
          require(msg.sender == ownerOf(_tokenId), "Only the token owner can change the render method");
          _renderTokenOffChain[_tokenId] = _renderOffChain;
      }

      function toggleWrapSVG() external onlyOwner {
          shouldWrapSVG = !shouldWrapSVG;
      }
  
      function toggleMinting() external onlyOwner {
          isMintingPaused = !isMintingPaused;
      }

      function withdraw() external onlyOwner nonReentrant {
          uint256 balance = address(this).balance;
          uint256 amount = (balance * (10000 - DEVELOPER_FEE)) / 10000;
  
          address payable receiver = payable(owner());
          address payable dev = payable(0xEA208Da933C43857683C04BC76e3FD331D7bfdf7);
  
          Address.sendValue(receiver, amount);
          Address.sendValue(dev, balance - amount);
      }
  }  
  