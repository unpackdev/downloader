
 // SPDX-License-Identifier: Apache-2.0


/* @author
* ██╗       █████╗  ██╗   ██╗ ███╗   ██╗  ██████╗ ██╗  ██╗ ██╗ ███████╗ ██╗
* ██║      ██╔══██╗ ██║   ██║ ████╗  ██║ ██╔════╝ ██║  ██║ ██║ ██╔════╝ ██║
* ██║      ███████║ ██║   ██║ ██╔██╗ ██║ ██║      ███████║ ██║ █████╗   ██║
* ██║      ██╔══██║ ██║   ██║ ██║╚██╗██║ ██║      ██╔══██║ ██║ ██╔══╝   ██║
* ███████╗ ██║  ██║ ╚██████╔╝ ██║ ╚████║ ╚██████╗ ██║  ██║ ██║ ██║      ██║
* ╚══════╝ ╚═╝  ╚═╝  ╚═════╝  ╚═╝  ╚═══╝  ╚═════╝ ╚═╝  ╚═╝ ╚═╝ ╚═╝      ╚═╝
*
* @custom: version 1.0.0
*/

        pragma solidity >=0.8.13 <0.9.0;

        import "./Ownable.sol";
        import "./ERC721A.sol";
        import "./Strings.sol";
        import "./ReentrancyGuard.sol";
        import "./MerkleProof.sol";
        import "./DefaultOperatorFilterer.sol";
               import "./ERC2981.sol"; // ERC2981 NFT Royalty Standard
        
        contract zkFarmers is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer , ERC2981{

            using Strings for uint256;       

            uint256 public price;
            uint256 _maxSupply;
            uint256 maxMintAmountPerTx;
            uint256 maxMintAmountPerWallet;
            
            string baseURL = "";
            string ExtensionURL = ".json";
            bool public paused = true;
            
            bool public publicMintStatus = false;
            bool public whitelistFeature = false;
            
                  bytes32 public MerkleGroupRoot1stADT = 0x1aa84f7db945285e641569f06a5f884b30340cebe5cafcaa0dbc6ce0a09c39b3;
                  uint256 public MerklePrice1stADT = 0.001 ether;
                  uint256 public MerkleMaxWallet1stADT = 5;
                  
                  bytes32 public MerkleGroupRootFREE = 0x1aa84f7db945285e641569f06a5f884b30340cebe5cafcaa0dbc6ce0a09c39b3;
                  uint256 public MerklePriceFREE = 0.0 ether;
                  uint256 public MerkleMaxWalletFREE = 1;
                  
                  bytes32 public MerkleGroupRootMASS = 0x1aa84f7db945285e641569f06a5f884b30340cebe5cafcaa0dbc6ce0a09c39b3;
                  uint256 public MerklePriceMASS = 0.0008 ether;
                  uint256 public MerkleMaxWalletMASS = 10;
                  
            address Service = 0x64249ED5Ef7a004d268A508092851e987482a175 ;
            address ServiceReferral = 0x1c3eB19A7128d870d69f9D2e8955796E2Ba8C589 ;

            uint256 public ServiceFee = 0.0006053 ether;



            error ContractPaused();
            error MaxMintWalletExceeded();
            error MaxSupply();
            error InvalidMintAmount();
            error InsufficientFund();
            error NoSmartContract();
            error TokenNotExisting();
            error NotWhitelistMintEnabled();
            error InvalidProof();



            constructor(uint256 _price, uint256 __maxSupply, string memory _initBaseURI, uint256 _maxMintAmountPerTx, uint256 _maxMintAmountPerWallet) ERC721A("ZKB OAT", "ZKBS") {

                baseURL = _initBaseURI;
                price = _price;
                _maxSupply = __maxSupply;
                maxMintAmountPerTx = _maxMintAmountPerTx;
                maxMintAmountPerWallet = _maxMintAmountPerWallet;
                
                 _setDefaultRoyalty(0x6dF2B40dd7B2a438a7186A11E4d7513eC7d86213, 200); 

            }

            modifier mintCompliance(uint256 _mintAmount) {
                if (msg.sender != tx.origin) revert NoSmartContract();
                if (totalSupply()  + _mintAmount > _maxSupply) revert MaxSupply();
                if(paused) revert ContractPaused();
            _;
        }

            modifier mintPriceCompliance(uint256 _mintAmount) {
                if(balanceOf(_msgSender()) + _mintAmount > maxMintAmountPerWallet) revert MaxMintWalletExceeded();
                if (msg.value < ((price + ServiceFee )*_mintAmount)) revert InsufficientFund();
                if (msg.value < price * _mintAmount) revert InsufficientFund();              
            _;
        }
        
        modifier whitelistMintPriceCompliance(bytes32[] calldata _merkleProof, uint256 _mintAmount) {
          bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
          if(checkMaxMintPerUser(_merkleProof, leaf, _mintAmount) == false) revert MaxMintWalletExceeded();
          if (_mintAmount < 0 || _mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
          require(msg.value >= checkPricePerUser(_merkleProof, leaf) * _mintAmount, "Insufficient Fund");        
          _;
        }
        
            // ================== Mint Function =======================

             function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) whitelistMintPriceCompliance(_merkleProof, _mintAmount) {
                if (!whitelistFeature) revert NotWhitelistMintEnabled() ;
                bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
                if(checkProofPerUser(_merkleProof, leaf) == false) revert InvalidProof() ;
                payFee(Service, ServiceFee * _mintAmount);
      
                _safeMint(_msgSender(), _mintAmount);
            }  

            function mint(uint256 _mintAmount) public payable  mintCompliance(_mintAmount)  mintPriceCompliance(_mintAmount) { 
              require(publicMintStatus, "Public Mint is not open!");                          
              payFee(Service, ServiceFee * _mintAmount);
                
              _safeMint(_msgSender(), _mintAmount);
            }

            // ================== Orange Functions (Owner Only) ===============

            function pause() public onlyOwner {
                paused = !paused;
            }

            function safeMint(address to, uint256 quantity) public onlyOwner mintCompliance(quantity) {
                _safeMint(to, quantity);
            }

            function airdrop(address[] memory _receiver, uint256 _mintAmount) public onlyOwner mintCompliance(_mintAmount){
                for (uint256 i = 0; i < _receiver.length; i++) {
                    safeMint(_receiver[i], _mintAmount);  
                }
            }
            
            function setbaseURL(string memory uri) public onlyOwner{
                baseURL = uri;
            }

            function setExtensionURL(string memory uri) public onlyOwner{
                ExtensionURL = uri;
            }

            function setCostPrice(uint256 _cost) public onlyOwner{
                price = _cost;
            }

            function setMaxSupply(uint256 supply) public onlyOwner{
                _maxSupply = supply;
              }
      
              function setMaxMintAmountPerTx(uint256 perTx) public onlyOwner{
                maxMintAmountPerTx = perTx;
              }
      
              function setMaxMintAmountPerWallet(uint256 perWallet) public onlyOwner{
                maxMintAmountPerWallet = perWallet;
              } 

            function _startTokenId() internal view virtual override returns (uint256) {
                return 1;
            }

            
            // ====================== Whitelist Feature ============================

            function setwhitelistFeature(bool state) public onlyOwner{
                whitelistFeature = state;
            }

            function setpublicMintStatus(bool state) public onlyOwner{
              publicMintStatus = state;
            }
            
            function checkProofPerUser(bytes32[] memory _merkleProof, bytes32 leaf) view public returns (bool){

              if(MerkleProof.verify(_merkleProof, MerkleGroupRoot1stADT, leaf)) return true ;
           if(MerkleProof.verify(_merkleProof, MerkleGroupRootFREE, leaf)) return true ;
           if(MerkleProof.verify(_merkleProof, MerkleGroupRootMASS, leaf)) return true ;
           
              return false;
          }

            function checkPricePerUser(bytes32[] memory _merkleProof, bytes32 leaf) view public returns (uint256){

                if(MerkleProof.verify(_merkleProof, MerkleGroupRoot1stADT, leaf)) return MerklePrice1stADT ;
             if(MerkleProof.verify(_merkleProof, MerkleGroupRootFREE, leaf)) return MerklePriceFREE ;
             if(MerkleProof.verify(_merkleProof, MerkleGroupRootMASS, leaf)) return MerklePriceMASS ;
             
                  
                  
                  return 0;
            }

            function checkMaxMintPerUser(bytes32[] memory _merkleProof, bytes32 leaf, uint256 amount) view public returns (bool){

              uint256 balance = (balanceOf(msg.sender) + amount);

              if(MerkleProof.verify(_merkleProof, MerkleGroupRoot1stADT, leaf)) {
                  if(balance <= MerkleMaxWallet1stADT) return true;
                  else return false;
                }
                 if(MerkleProof.verify(_merkleProof, MerkleGroupRootFREE, leaf)) {
                  if(balance <= MerkleMaxWalletFREE) return true;
                  else return false;
                }
                 if(MerkleProof.verify(_merkleProof, MerkleGroupRootMASS, leaf)) {
                  if(balance <= MerkleMaxWalletMASS) return true;
                  else return false;
                }
                 
                return false;
          }
          
          
          function updateHashRootForAll(bytes32[] memory hashRootArray, uint256[] memory PriceArray, uint256[] memory  MaxMintArray)  public { 
            require(hashRootArray.length <= 3, "Too many inputs on the hash root!");
            require(PriceArray.length <= 3, "Too many inputs on the Price!");
            require(MaxMintArray.length <= 3, "Too many inputs on the Max mint amount!");

            
                MerkleGroupRoot1stADT = hashRootArray[0];
                MerklePrice1stADT = PriceArray[0];
                MerkleMaxWallet1stADT = MaxMintArray[0];
                
                MerkleGroupRootFREE = hashRootArray[1];
                MerklePriceFREE = PriceArray[1];
                MerkleMaxWalletFREE = MaxMintArray[1];
                
                MerkleGroupRootMASS = hashRootArray[2];
                MerklePriceMASS = PriceArray[2];
                MerkleMaxWalletMASS = MaxMintArray[2];
                

          }
                  
                  
            

            // ================================ Withdraw Function ====================

            function withdraw() public onlyOwner nonReentrant{
              uint _balance = address(this).balance;
              
                  
                      payable(0xf421074Bbd76D9a5776585846f4a94eB5463Fd49).transfer(_balance * 50 / 100);
                      
                      
                      payable(0x4723740Af3263f5B9a4D9f93169913c44713aa03).transfer(_balance * 30 / 100);
                      
                      
                      payable(0x776De3d19D613362b5B1e3aDB946b274a764f041).transfer(_balance * 20 / 100);
                      
                      
              
              (bool owner, ) = payable(owner()).call{value: address(this).balance}('');
              require(owner);    
          }

            // =================== Blue Functions (View Only) ====================

            function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory){

                if (!_exists(tokenId)) revert TokenNotExisting();
                
                string memory currentBaseURI = _baseURI();
                return bytes(currentBaseURI).length > 0
                    ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ExtensionURL))
                    : '';
            }

            function _baseURI() internal view virtual override returns (string memory) {
                return baseURL;
            }

            function maxSupply() public view returns (uint256){
                return _maxSupply;

            }  

            //internal
                  function payFee(
                    address to,
                    uint256 amount
                  ) internal {
                    
                    
                    uint256 referralFee = amount * 5 / 100;
                    (bool referral, ) = payable(ServiceReferral).call{value: referralFee}('');
                    require(referral, "Referral Payment failed");
            
                    uint256 serviceAmount = amount - referralFee;
                    

                  (bool success, ) = payable(to).call{value: serviceAmount}('');
                  require(success, "Payment failed");
                  }

            
              /// @dev internal function to 
              /// @param from  user address where token belongs
              /// @param to  user address
              /// @param tokenId  number of tokenId
                function transferFrom(address from, address to, uint256 tokenId) public payable  override onlyAllowedOperator(from) {
              super.transferFrom(from, to, tokenId);
              }
             
              /// @dev internal function to 
              /// @param from  user address where token belongs
              /// @param to  user address
              /// @param tokenId  number of tokenId
              function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
              super.safeTransferFrom(from, to, tokenId);
              }
      
              /// @dev internal function to 
              /// @param from  user address where token belongs
              /// @param to  user address
              /// @param tokenId  number of tokenId
              function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
              public payable
              override
              onlyAllowedOperator(from)
              {
              super.safeTransferFrom(from, to, tokenId, data);
              }

            
          /**
         * @dev _setDefaultRoyalty - set same royalities for all collection 
         */
          function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner{
        _setDefaultRoyalty(_receiver, _feeNumerator);
        }
        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
        }
        
        }      
        