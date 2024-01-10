// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract cybercity is ERC1155, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;    

    // Events
    event sellStart(uint256 tokenId);
    event sellStop(uint256 tokenId);   
    // Constants

    // Token IDs
    uint256 private constant REDEMPTION_TOKEN = 1; 
    uint256 private constant  RESIDENT_PASS = 2;
    // Sell lifecycle states
    uint256 private constant REDEMPTION_WHITELIST = 1;
    uint256 private constant REDEMPTION_PUBLIC = 2;
    uint256 private constant RESIDENT_WHITELIST = 3;
    uint256 private constant RESIDENT_FREEMINT = 4;
    uint256 private constant RESIDENT_PUBLIC = 5;
    uint256 private constant SELL_DISABLED = 9;
    string private constant  _metaDataUri = "ipfs://Qmb3udsjQrejVrZDKcRjALYG7bCpWvDhF1iwTqccpdaBQV/";
    string private constant _contractURI = "https://ipfs.io/ipfs/QmdUFj45bezoLNocd9zc7u8MLSeNta2Rdpe8F5TFCQcMxJ";
    uint256 private constant _MaxMint = 5;
    uint256 private constant _maxRedemptionSupply = 3000;
    uint256 private constant _maxResidentSupply = 10000;
    uint256 private constant _redemptionWLPrice = 0.08 ether;
    uint256 private constant _redemptionPrice = 0.12 ether;    
    address private constant _withdrawWallet = address(0xa3206DCDbfd313eEEb6F028fF27837421AfF7b20);

    // State Variables

    string public name = "Cyber City";
    string public symbol = "CCY";
    bool private _paused;
    bool private _redemptionSellStarted = false;
    bool private _ResidentSellStarted = false;  
    uint256 private _lastMinted = 0;
    mapping(address => uint256) private _redemptionWhitelist; // Mapping address and whitelisted round
    mapping(address => uint256) private _residentWhitelist; // Mapping address and whitelisted round    
    uint256 private _redemptionCurrentSupply = 0;
    uint256 private _residentCurrentSupply = 0;  
    uint256 private _redemptionSelltimeStamp = 0;
    uint256 private _residentSelltimeStamp = 0;
    address private _proxyRegistryAddress; // OpenSea proxy registry address
    uint256 private  _residentWLPrice = 0.0003 ether;      
    uint256 private  _residentPrice = 0.0003 ether;  

    constructor(address __proxyRegistryAddress) ERC1155(_metaDataUri) {
        _proxyRegistryAddress = __proxyRegistryAddress;
    }

    /**
     * @dev Pauses / Resume contract operation.
     *
     */

    function Pause() public onlyOwner {
        _paused = !_paused;
    }

    /**
     * @dev Mints tokens 
     *
     * Requirements:
     *   
     * - Contract not paused
     * - Valid token ID value 1 = REDEMPTION_TOKEN / 2 = RESIDENT_PASS
     * - Sell must be enabled
     * - Posible sell stages:
     *   - REDEMPTION_WHITELIST(1): Only round 1 whitelisted wallts can mint
     *   - REDEMPTION_PUBLIC(2): Every wallet can mint
     *   - RESIDENT_WHITELIST(3): Only round 2 whitelisted wallets can mint
     *   - RESIDENT_FREEMINT(4): Cannot mint in this method. User muist transfer REDEMPTION TOKENS.
     *   - RESIDENT_PUBLIC(5): Every wallet can mint until reach max supply
     *   - SELL_DISABLED(9): Cannot mint
     * - Every wallet can mint a maximun of 3 REDEMPTION or RESIDENT tokens
     */

    function mint(uint256 tokenId, uint256 qty) public payable {
        require(!_paused,"Contract Paused");    
        require(tokenId == REDEMPTION_TOKEN || tokenId == RESIDENT_PASS, "Bad ID");      
        uint256 _currentStage = _getSellStage();
        require(_currentStage != SELL_DISABLED,"Sell disabled");      
        require(tokenId == REDEMPTION_TOKEN ? _redemptionCurrentSupply + qty <= _maxRedemptionSupply : _residentCurrentSupply + qty <= _maxResidentSupply, "Max supply");    
        require(msg.value >= _getPrice(tokenId).mul(qty), "Wrong amt");    
        require(balanceOf(msg.sender, tokenId).add(qty) <= _MaxMint,"Max mint");
        if (tokenId == REDEMPTION_TOKEN) {require(_currentStage==REDEMPTION_WHITELIST || _currentStage==REDEMPTION_PUBLIC,"Sell disabled");}

        if (tokenId == REDEMPTION_TOKEN) {require(_redemptionSellStarted,"Cannot sell");}
        if (tokenId == RESIDENT_PASS) {require(_ResidentSellStarted,"Cannot sell");}

        if (tokenId == REDEMPTION_TOKEN && _currentStage == REDEMPTION_WHITELIST) {
            require(_redemptionWhitelist[msg.sender] == 1,"Not Whitelisted");
        }
        if (tokenId == RESIDENT_PASS && _currentStage == RESIDENT_WHITELIST) {
            require(_residentWhitelist[msg.sender] == 2,"Not Whitelisted");
        }
        if (tokenId == RESIDENT_PASS && _currentStage == RESIDENT_FREEMINT) {
            // For resident pass free mint must invoke freeMint method
            revert();
        }
        
        tokenId == REDEMPTION_TOKEN ? _redemptionCurrentSupply+=qty : _residentCurrentSupply+=qty;     
        _mint(msg.sender, tokenId, qty, "");  
    }

    /**
     * @dev Empty receive function.
     *
     * Requirements:
     *   
     * - Cannot send plain ether to this contract
     */

      receive () external payable { revert(); }

    /**
     * @dev EmptyERC155 Token holder interface implementacion 
     *
     * Requirements:
     *   
     * - Cannot send plain ether to this contract
     */

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev EmptyERC155 Token holder interface implementacion (batch mode)
     *
     * Requirements:
     *   
     * - Cannot send plain ether to this contract
     */

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Mint NFT: This function is for mint REDEMPTION AND RESIDENT TOKENS, NFTs are
     * minted with supply 0.
     * At first call mints REDEMPTION TOKEN NFT and in second call MINTS RESIDENT PASS NFT
     *
     * Requirements:
     *   
     * - Contract not paused.
     * - Only contract owner can mint NFTs
     */

    function mintNFT() external onlyOwner {
        require(!_paused,"Contract Paused");
        require(msg.sender != address(0),"Zero address");    
        require(_lastMinted <= 2,"NFT mint disabled");
        
        _lastMinted = _lastMinted.add(1);
        (_lastMinted == 1) ? _redemptionCurrentSupply+=1:_residentCurrentSupply+=1;
        _mint(owner(), _lastMinted, 1, "");
    }

    function freeRedemption( address[] calldata __wallets, uint256 __qty ) external onlyOwner {
        require(!_paused,"Contract Paused");
        require(msg.sender != address(0),"Zero address");    
        
        for(uint i =0; i< __wallets.length; i++) {  
            _redemptionCurrentSupply+=__qty;
            _mint(__wallets[i], 1, __qty, "");
        }
    }

    /**
     * @dev Whitelist: This function is for add wallets to REDEMPTION AND RESIDENT TOKENs whitelist
     * Requirements:
     *   
     * - Contract not paused.
     * - Only contract owner can whitelist wallets
     */

    function whitelist( address[] calldata wallet, uint256 token_id) external onlyOwner {
        require(!_paused,"Contract Paused");
        require(token_id == REDEMPTION_TOKEN || token_id == RESIDENT_PASS, "Bad ID");
        for(uint i =0; i< wallet.length; i++){              
            (token_id == 1) ? _redemptionWhitelist[wallet[i]] = token_id : _residentWhitelist[wallet[i]] = token_id;
        }            
    }

    /**
     * @dev whitelistRemove: This function is for remove  wallets from REDEMPTION AND RESIDENT TOKENs whitelist
     * Requirements:
     *   
     * - Contract not paused.
     * - Only contract owner can remove wallets 
     * - Wallet must be whitelisted
     */
    function whiteListRemove( address __wallet ) external onlyOwner {
        require(! _paused );
        require(__wallet != address(0),"Zero address");
        require(__wallet != owner(),"Owner Address");

        delete _redemptionWhitelist[__wallet];
        delete _residentWhitelist[__wallet];
    }

    /**
     * @dev startSell: Signals sell period start for the selected token.
     *   
     * - Contract not paused.
     * - Only contract owner can start sell
     */

    function startSell( uint256 token_id ) external onlyOwner {
        require(!_paused,"Contract Paused");
        require(token_id == REDEMPTION_TOKEN || token_id == RESIDENT_PASS, "Bad ID");      

        if (token_id == REDEMPTION_TOKEN) {
            _redemptionSellStarted = true;
            _redemptionSelltimeStamp = block.timestamp;
        } else {
            require(_redemptionSelltimeStamp > 0 ,"Start Redemption First");
            _ResidentSellStarted = true;
            _residentSelltimeStamp = block.timestamp;
        }
        emit sellStart(token_id);
    }

    /**
     * @dev stopSell: Stops REDEMPTION TOKEN sell period. 
     *   
     * - Contract not paused.
     * - Only contract owner can stop sell
     */

    function stopSell() external onlyOwner {
        require(!_paused,"Contract Paused");
        require(_redemptionSellStarted,"Not started");
        _redemptionSellStarted = false;
        emit sellStop(1);
    }  

    /**
     * @dev withDraw: Sends contracts ethers to owner wallet.
     *   
     * - Contract not paused.
     * - Only contract owner can whitelist wallets
     */

    function withdraw( uint256 __amount) external onlyOwner {
        require(! _paused );
        require(__amount <= address(this).balance);
        address payable _to = payable(_withdrawWallet);
        (bool sent, bytes memory data) = _to.call{value: __amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev setResidentPrice: Set redemption token, Whitelist and Public Sell price.
     *   
     * - Contract not paused.
     * - Only contract owner can whitelist wallets
     * - Prices must be greater then zero
     */

    function setResidentPrices( uint256 _WLPrice, uint256 _PublicPrice) external onlyOwner {
        require(! _paused );        
        require( _WLPrice > 0 || _PublicPrice > 0, "Invalid Price" );  

        _residentWLPrice = _WLPrice;      
         _residentPrice = _PublicPrice;  
    }

    /**
     * @dev isWhitelisted: Query if a wallet address is whitelisted
     *   
     */

    function isWhitelisted( address wallet, uint256 tokenId ) public view returns(bool) {
        return (tokenId == 1) ? _redemptionWhitelist[wallet] == tokenId : _residentWhitelist[wallet] == tokenId;
    }
    /**
     * @dev balance: eth balance for this contract
     *   
     */
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
    /**
     * @dev uri: Returns metada file URI for the selected NFT
     *   
     */    
    function uri(uint id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_metaDataUri, Strings.toString(id)));
    }
    /**
     * @dev baseTokenURI: Returns contract base URI for metadata files
     *   
     */    
    function baseTokenURI() external pure  returns (string memory) {
        return _metaDataUri;
    }  
    /**
     * @dev contractURI: Returns contract METADATA for Opensea Collection Descripcion
     *   
     */    
    function contractURI() external pure returns (string memory) {
        return _contractURI;
    }
    /**
     * @dev paused: Returns contract pause status
     *   
     */        

    function paused() external view  returns (bool) {
        return _paused;
    }  

    /**
     * @dev tokenInfo: Returns basic token information for selected token ID
     *   
     * - MaxSupply
     * - Current Supply
     * - Token mint Price in wei
     * - Sell status for the selected token
     */        

    function tokenInfo(uint256 tokenId) public view returns (uint256,uint256,uint256,uint256,bool,uint256) {
        if (tokenId == REDEMPTION_TOKEN) {
            return (_maxRedemptionSupply, _redemptionCurrentSupply, _redemptionPrice,_redemptionWLPrice, _redemptionSellStarted, _redemptionSelltimeStamp);
        } else {
            return (_maxResidentSupply, _residentCurrentSupply, _residentPrice, _residentWLPrice, _ResidentSellStarted, _residentSelltimeStamp);
        }
    }

    /**
     * @dev isMinted: Returns NFT mint status for selected token ID
     *   
     */        

    function isMinted( uint256 tokenId) public view returns (bool) {
        return (_lastMinted >= tokenId);
    }

    /**
     * @dev getSellStage: Returns current sell stage relative to start sell timestamp 
     * and current block timestamp
     *   
     */        

    function getSellStage() public view returns (uint256) {
        return _getSellStage();
    }

    /**
     * @dev isApprovedForAll: Returns isApprovedForAll standar ERC1155 method modified to return
     * always true for Opensea proxy contract. (frictionless opensea integration)  
     * See Opensea tradable token.
     */        

    function isApprovedForAll(
        address account, 
        address operator
        ) 
        public 
        view 
        virtual 
        override returns (bool) {  
            // Whitelist OpenSea proxy contract for easy trading.
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(account)) == operator) {
                return true;
            }          

            return super.isApprovedForAll(account,operator);
    }
    /**
     * @dev getPrice: Return selected token mint price.
     */        

    function getPrice( uint256 tokenId) public view returns (uint256) {       
        return _getPrice(tokenId);
    } 

    /**
     * @dev burn: Burns contract's obtained REDEMPTION tokens balance from RESIDENT PASS free mint.
     */        

    function burn() external onlyOwner returns (uint256) {
        require(!_paused,"Contract Paused");
        uint256 _amount = balanceOf(address(this),REDEMPTION_TOKEN);
        require(_amount > 0,"No founds");

        _redemptionCurrentSupply-=_amount;
        _burn(address(this),REDEMPTION_TOKEN,_amount);

        return _amount;
    }

    /**
     * @dev _getPrice: Return selected token mint price.
     */        

    function _getPrice( uint256 tokenId) private view returns (uint256) {
        uint256 _currentSellStage = _getSellStage();

        if (tokenId == REDEMPTION_TOKEN && _currentSellStage == REDEMPTION_WHITELIST) {
            return _redemptionWLPrice;
        }
        if (tokenId == REDEMPTION_TOKEN && _currentSellStage == REDEMPTION_PUBLIC) {
            return _redemptionPrice;
        }
        if (tokenId == RESIDENT_PASS && _currentSellStage == RESIDENT_WHITELIST) {
            return _residentWLPrice;
        }
        if (tokenId == RESIDENT_PASS && _currentSellStage == RESIDENT_PUBLIC) {
            return _residentPrice;
        }
        if (tokenId == REDEMPTION_TOKEN ) {
            return _redemptionPrice;
        }
        
        return _residentPrice;
    } 

    /**
     * @dev _getSellStage: Returns current sell stage relative to start sell timestamp 
     * and current block timestamp
     *   
     */        

    function _getSellStage() private view returns (uint256) {
        if (!_redemptionSellStarted && _redemptionSelltimeStamp == 0) {return SELL_DISABLED;}
        if (!_redemptionSellStarted && _redemptionSelltimeStamp > 0 && !_ResidentSellStarted) {return SELL_DISABLED;}    
        // REDEMPTION TOKEN STAGES
        if (_redemptionSellStarted) {
            if (block.timestamp.sub(_redemptionSelltimeStamp) < 86400) {
                return REDEMPTION_WHITELIST;
            } else {
                return REDEMPTION_PUBLIC;
            }
        }
        // RESIDENT TOKEN STAGES    
        if (_ResidentSellStarted) {
            if (block.timestamp.sub(_residentSelltimeStamp) < 86400) {      
                return RESIDENT_WHITELIST;
            }
            if (block.timestamp.sub(_residentSelltimeStamp) < 172800) {      
                return RESIDENT_FREEMINT;
            } else {
                return RESIDENT_PUBLIC;
            }
        } 
        return SELL_DISABLED;
    }

    /**
     * @dev _beforeTokenTransfer: Modified _safeTransfer trigger to implement RESIDENT PASS FREE MINT.
     * After successfull transfer of REDEMPTION Tokens from user wallet to contract address, this function mints 
     * one RESIDENT PASS TOKEN for each REDEMPTION TOKEN received.
     *
     */        

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(!_paused,"Contract Paused");    
        if (from != address(0) && from != address(this)) {
            require(operator == from,"Invalid mint");
            uint arrayLength = ids.length;
            uint256 _sellStage = _getSellStage();
            require(_sellStage == RESIDENT_FREEMINT || _sellStage == RESIDENT_PUBLIC,"Invalid stage");
            if (to == address(this)) {
                for (uint i=0; i<arrayLength; i++) {
                    if (ids[i] == RESIDENT_PASS) {revert();}
                    if (ids[i] == REDEMPTION_TOKEN) {
                    _residentCurrentSupply+=amounts[i];
                    _mint(from, RESIDENT_PASS, amounts[i], data);                    
                    }                
                }
            }            
        }
    }    
}