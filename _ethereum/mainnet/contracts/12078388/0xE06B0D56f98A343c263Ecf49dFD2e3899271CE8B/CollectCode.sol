// SPDX-License-Identifier: MIT
// Same version as openzeppelin 3.4
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Utils.sol";

// import "./ERC721Holder.sol";  // for ECR721Holder.test.js

abstract contract CollectCode is ERC721, Ownable
{
    using SafeMath for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Config {
        string seriesCode;
        uint256 initialSupply;
        uint256 maxSupply;
        uint256 initialPrice;
        uint8 width;
        uint8 height;
    }
    Config internal config_;

    struct State {
        bool isReleased;            // Token Zero was minted
        uint256 mintedCount;        // (ignores Token Zero)
        uint256 builtCount;         // (ignores Token Zero)
        uint256 notBuiltCount;      // (ignores Token Zero)
        uint256 currentSupply;      // permitted to mint
        uint256 availableSupply;    // not minted
        uint256 maxBuyout;          // not minted
        bool isAvailable;           // availableSupply > 0
    }
    State internal state_;

    struct TokenInfo {
        address owner;
        bool youOwnIt;
        bool isBuilt;
        uint256 sequenceNumber;
        uint256[] sequenceTokens;
        string pixels;
    }

    mapping (uint256 => bytes) internal _pixels;
    mapping (uint256 => uint256) internal _sequenceNumber;

    constructor()
    {
        state_ = State(
            false,  // isReleased
            0,      // mintedCount
            0,      // builtCount
            0,      // notBuiltCount
            0,      // currentSupply
            0,      // availableSupply
            0,      // maxBuyout
            false   // isAvailable
        );
    }

    //
    // public actions
    function giftCode(address to) onlyOwner public returns (uint256)
    {
        require(!state_.isReleased, "CC: Token Zero already issued");
        require(to == owner(), "CC: Not Contract owner");
        //require(isOwner(), "CC: Not Contract owner"); // Ownable takes care
        return mintCode_( to, 1, true );
    }
    function buyCode(address to, uint256 quantity, bool build) public payable returns (uint256)
    {
        require(state_.isReleased, "CC: Not for sale yet");
        require(msg.value == calculatePriceForQuantity(quantity), "CC: Value do not match quantity");
        return mintCode_( to, quantity, build );
    }
    function buildCode(uint256 tokenId) public returns (bool)
    {
        require(_exists(tokenId), "CC: Token does not exist");
        require(_pixels[tokenId].length == 0, "CC: Token already built");
        require(msg.sender == ownerOf(tokenId), "CC: Not Token owner");
        buildCode_( msg.sender, tokenId, 0 );
        return true;
    }
    function withdraw() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }

    //
    // public getters
    function getConfig() public view returns (Config memory)
    {
        return config_;
    }
    function getState() public view returns (State memory)
    {
        return state_;
    }
    function getTokenInfo(address from, uint256 tokenId) public view returns (TokenInfo memory)
    {
        require(_exists(tokenId), "CC: Token query for nonexistent token");
        uint256[] memory sequenceTokens;
        if(_sequenceNumber[tokenId] > 0) {
            // find this token's complete sequence
            uint256 tokenCount = _sequenceNumber[tokenId];
            for(uint256 t = tokenId+1 ; _sequenceNumber[t] > 0 && _sequenceNumber[t] > _sequenceNumber[tokenId] ; ++t)
                tokenCount++;
            sequenceTokens = new uint256[](tokenCount);
            for(uint256 i = 0 ; i < tokenCount ; ++i)
                sequenceTokens[i] = tokenId-_sequenceNumber[tokenId]+1+i;
        }
        return TokenInfo(
            ownerOf(tokenId),               // owner address
            (from == ownerOf(tokenId)),     // sender owns it
            (_pixels[tokenId].length > 0),  // is built
            _sequenceNumber[tokenId],       // build sequential number
            sequenceTokens,                 // sequence of tokens
            Utils.convertBytesToHexString(_pixels[tokenId])  // pixels
        );
    }
    function calculatePriceForQuantity(uint256 quantity) public view returns (uint256)
    {
        uint256 price = 0;
        for(uint256 i = 1 ; i <= quantity ; i++)
            price += state_.mintedCount.add(i) * config_.initialPrice * 10000000000000000; // 1 ETH=1000000000000000000
        return price;
    }
    function getPrices() public view returns (uint256[] memory)
    {
        uint256 quantity = 0;
        if(totalSupply() > 0 && totalSupply() < config_.maxSupply)
            quantity = Utils.max_uint256(state_.maxBuyout, 1);
        uint256[] memory prices = new uint[](quantity);
        for(uint256 i = 1 ; i <= quantity ; i++)
            prices[i-1] = calculatePriceForQuantity(i);
        return prices;
        //return Utils.convertArrayToString_uint256(prices);
    }
    function getOwnedTokens(address from) public view returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint[](balanceOf(from));
        for(uint256 i = 0 ; i < tokenIds.length ; i++)
            tokenIds[i] = tokenOfOwnerByIndex(from, i);
        return tokenIds;
        //return Utils.convertArrayToString_uint256(tokenIds);
    }

    //
    // Privates
    //

    function mintCode_(address to, uint256 quantity, bool build) internal returns (uint256)
    {
        require(quantity > 0, "CC: Quantity must be positive");

        if( state_.isReleased )
        {
            require(state_.mintedCount < config_.maxSupply, "CC: Sold out");
            require(state_.mintedCount < state_.currentSupply, "CC: Sales on hold");
            require(state_.mintedCount.add(quantity) <= state_.currentSupply, "CC: Quantity not available");
            require(quantity <= state_.maxBuyout, "CC: Quantity not allowed");
        }

        for(uint256 i = 0 ; i < quantity ; i++)
        {
            if( state_.isReleased ) {
                _tokenIds.increment();
            }
            uint256 newTokenId = _tokenIds.current();
            _mint( to, newTokenId );

            // update contract state
            state_.isReleased = true;
            state_.mintedCount = newTokenId;
            if(newTokenId > 0)
                state_.notBuiltCount++;
            
            if( build ) {
                buildCode_(to, newTokenId, quantity == 1 ? 0 : (i+1));
            } else {
                calculateSupply_();
                makeTokenURI_(newTokenId);
            }
        }

        return quantity;
    }

    function buildCode_(address to, uint256 tokenId, uint256 sequenceNumber) internal
    {
        // make colors
        uint8[] memory c3 = Utils.reduceColors(
            bytes20(address(this)),   // seed 1: contract address
            bytes20(to),              // seed 2: owner address
            Utils.getBlockSeed(),     // seed 3: block hash
            uint8(config_.width*2), tokenId*config_.width);
        // make pixels
        for(uint8 y = 0 ; y < config_.width ; y++) {
            for(uint8 x = 0 ; x < config_.width ; x++) {
                _pixels[tokenId].push(byte(Utils.step_uint8( c3[x*3+0], c3[(x+config_.width)*3+0], config_.width, y )));
                _pixels[tokenId].push(byte(Utils.step_uint8( c3[x*3+1], c3[(x+config_.width)*3+1], config_.width, y )));
                _pixels[tokenId].push(byte(Utils.step_uint8( c3[x*3+2], c3[(x+config_.width)*3+2], config_.width, y )));
            }
        }
        _sequenceNumber[tokenId] = sequenceNumber;

        // increase built count for supply (ignore Token Zero)
        if(tokenId > 0)
        {
            state_.notBuiltCount--;
            state_.builtCount++;
        }
        calculateSupply_();
        makeTokenURI_(tokenId);
    }

    function calculateSupply_() internal
    {
        if(state_.mintedCount < config_.initialSupply) {
            // Initial supply must go first
            state_.currentSupply = config_.initialSupply;
        }
        else {
            // Release 10% minus not build tokens
            uint256 surplus = Utils.percent_uint256(config_.maxSupply, 10);
            state_.currentSupply = state_.mintedCount   // minted
                + surplus                               // add 10%
                - Utils.clamp_uint256(state_.notBuiltCount, 0, surplus);    // minus not built
            if(state_.currentSupply > config_.maxSupply)
                state_.currentSupply = config_.maxSupply;
        }
        state_.availableSupply = state_.currentSupply - state_.mintedCount;
        state_.maxBuyout = Utils.min_uint256( state_.availableSupply, Utils.percent_uint256(config_.maxSupply, 5) );
        state_.isAvailable = (state_.availableSupply > 0);
    }

    function makeTokenURI_(uint256 tokenId) internal
    {
        _setTokenURI( tokenId,
            string(abi.encodePacked(
                "https://collect-code.com/api/token/", config_.seriesCode, 
                "/", Utils.utoa(uint(tokenId)), 
                "/metadata?pixels=", Utils.convertBytesToHexString(_pixels[tokenId])) )
        );
    }
}
