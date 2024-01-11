// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./ERC721MM.sol";


contract Heroes is ERC721MM {

    string constant public name   = "Meta & Magic Heroes";
    string constant public symbol = "HEROES";

    mapping(uint256 => uint256) bossSupplies;

    address stats;

    /*///////////////////////////////////////////////////////////////
                        INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(address stats_, address renderer_) external {
        require(msg.sender == _owner(), "not authorized");

        stats    = stats_;
        renderer = renderer_;

        bossSupplies[10] = 100;
    }

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getStats(uint256 id_) external view virtual returns(bytes10[6] memory stats_) {    // [][]
        uint256 seed = entropySeed;
        require(seed != 0, "Not revealed");

        stats_ = StatsLike(stats).getStats(_traits(seed, id_));
    }

    function isSpecial(uint256 id) external view returns(bool sp) {
        return _isSpecial(id, entropySeed);
    }
    function tokenURI(uint256 id) external view returns (string memory) {
        uint256 seed = entropySeed;
        if (seed == 0) return RendererLike(renderer).getPlaceholder(1);
        return RendererLike(renderer).getUri(id, _traits(seed, id), _getCategory(id,seed));
    }

    /*///////////////////////////////////////////////////////////////
                        MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintDrop(uint256 boss, address to) external virtual returns(uint256 id) {
        require(auth[msg.sender], "not authorized");

        id = 3000 + bossSupplies[boss]--; // Note boss drops are predictable because the entropy seed is known

        _mint(to, id, 2);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _traits(uint256 seed_, uint256 id_) internal pure override returns (uint256[6] memory t ) {
        require(seed_ != uint256(0), "seed not set");
        if (_isSpecial(id_, seed_)) return _getSpecialTraits(seed_, id_);
        
        t = [ _getTier(id_,  seed_, "LEVEL"), 
               _getClass(id_, seed_, "CLASS"), 
               _getTier(id_,  seed_, "RANK"), 
               _getTier(id_,  seed_, "RARITY"), 
               _getTier(id_,  seed_, "PET"),
               _getItem(id_,  seed_, "ITEM")];
            
        if (id_ > 3000) t[1] = 8;
    }

    function _getSpecialTraits(uint256 seed_, uint256 id_) internal pure returns (uint256[6] memory t) {
        uint256 spc = (id_ / 428) + 1;
        
        uint256 traitIndcator = (spc) * 10 + spc;

        t = [traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator,traitIndcator];
    }

    function _getClass(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 class_) {
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 

        if (rdn <= 79_8160) return (rdn % 5) + 1;
        if (rdn <= 91_7884) return 6;
        return 7;
    }

    function _getItem(uint256 id_, uint256 seed, bytes32 salt) internal pure returns (uint256 item_) {
        uint256 rdn = uint256(keccak256(abi.encode(id_, seed, salt))) % 100_0000 + 1; 
        if (rdn <= 24_9425) return 0;

        return _getTier(id_, seed, salt) + ((rdn % 3) * 6);
    }

    function _isSpecial(uint256 id, uint256 seed_) internal pure returns (bool special) {
        uint256 rdn = _getRndForSpecial(seed_);
        for (uint256 i = 0; i < 8; i++) {
            if (id == rdn + (428 * i)) {
                special = true;
                break;
            }
        }
    }

    function _getSpecialCategory(uint256 id, uint256 seed_) internal pure returns (uint256 spc) {
        uint256 num = (id / 428) + 1;
        spc = num + 4 + (num - 1);
    }

    function _getCategory(uint256 id, uint256 seed) internal pure returns (uint256 cat) {
        // Boss Drop
        if (id > 3000) return cat = 3;
        if (_isSpecial(id, seed)) return _getSpecialCategory(id, seed);
        return 1;
    }

    function _getRndForSpecial(uint256 seed) internal pure virtual returns (uint256 rdn) {
        rdn = uint256(keccak256(abi.encode(seed, "SPECIAL"))) % 428 + 1;
    }

}

interface StatsLike {
    function getStats(uint256[6] calldata attributes) external view returns (bytes10[6] memory stats_); 
}

interface RendererLike {
    function getUri(uint256 id, uint256[6] calldata traits, uint256 cat) external view returns (string memory meta);
    function getPlaceholder(uint256 cat) external pure returns (string memory meta);
}
