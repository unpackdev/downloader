// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MerkleProof.sol";
import "./BaseMint.sol";

/**
    Conditions:
        - Genesis and Whitelist happens same time
        - Addresses in claim gets a free mint, they can mint up to 2 at price .12
        - Addresses in diamond hand can mint up to 3 at price .12
        - Addresses in genesis can mint up to 2 at price .12
        - Addresses in whitelist can mint up to 1 at price .15
        - Addresses in waitlist can mint up to 1 at price .15
        - Public no sales, cannot mint through another contract, at price .18
 */

contract ZooverseGen2Controller is BaseMint {
    mapping(uint256 => mapping(address => bool)) private _whitelist;
    mapping (address => bool) private _claimed;

    uint256 private genesisLimit = 2;
    uint256 public genesisPrice = 0.12 ether;
    uint256 public whitelistPrice = 0.15 ether;
    uint256 private _lastSaleType;

    struct Sale {
        uint256 limit;
        uint256 liveIndex;
        bytes32 root;
    }

    mapping(uint256 => Sale) public sales;

    constructor() {
        // claim
        sales[1] = Sale(genesisLimit, 1, 0xe8673ee234e7ce0840f0c8b2df7486e7cad1433368b49d67ef3b6eac282ddb2d);
        // diamondhand
        sales[2] = Sale(genesisLimit + 1, 1, 0xb1915c4f45866c50eafd6e31b50005f7ee6e36130b2205d844d63be98e6ebcc1);
        // genesis
        sales[3] = Sale(genesisLimit, 1, 0xf9b463e9c56dd6e2cea744dd5e699ced04b36fd7c327b2614baaaedb38afa4fc);
        // whitelist
        sales[4] = Sale(1, 1, 0x1dd3a4f211ca8e7a0839f666370a647628d51b1718ffa362ce5d11b24bcfceda); 
        // waitlist
        sales[5] = Sale(1, 2, 0x8b357472e382e324c75a0b5af28d470e59c0c5c1d358315f512d967c1a3dca5d);
        _lastSaleType = 5;
    }

    modifier correctMintConditions(uint256 saleType, uint256 quantity, bytes32[] calldata proof) {
        require(currentStage == sales[saleType].liveIndex, "Not Live");
        require(nft.getAux(msg.sender) + quantity <= sales[saleType].limit, "Exceeds limit");
        require(isPermitted(saleType, msg.sender, proof), "Not verified user");        
        _;
    }

    function salesMint(uint256 quantity, bytes32[] calldata proof, uint256 saleType) 
        external 
        payable 
        callerIsUser
        correctMintConditions(saleType, quantity, proof) 
    {
        uint256 mintQuantity = quantity;
        if(saleType == 1) {
            if(!_claimed[msg.sender]) {
                unchecked {
                    mintQuantity++;
                }
                _claimed[msg.sender] = true;
            }
        }        
        require(msg.value >= quantity * discountedPrice(saleType), "Not enough eth");
        nft.setAux(msg.sender, uint64(nft.getAux(msg.sender) + quantity));
        _mint(mintQuantity, msg.sender);
    }

    function _verify(uint256 saleType, address account, bytes32[] calldata proof) internal view returns (bool) {
        return MerkleProof.verify(proof, sales[saleType].root, keccak256(abi.encodePacked(account)));
    }

    function isPermitted(uint256 saleType, address account, bytes32[] calldata proof) public view returns (bool) {
        return _verify(saleType, account, proof) || _whitelist[saleType][account];
    }

    function getSaleType(address account, bytes32[] calldata proof) public view returns (uint256) {        
        for(uint256 i = 1; i <= _lastSaleType;) {
            if(isPermitted(i, account, proof)) return i;
            unchecked {
                i++;   
            }
        }
        return 0;
    }

    function availableToMint(address account, bytes32[] calldata proof) public view returns (uint256) {
        if(currentStage == 1 || currentStage == 2) {
            uint256 balance = nft.getAux(account);
            uint256 saleType = getSaleType(account, proof);
            if(saleType == 0) return 0;
            return sales[saleType].limit - balance;
        }
        if(currentStage == 3) return maxPerTx;
        return 0;
    }

    function discountedPrice(uint256 saleType) public view returns (uint256) {
        if(saleType > 3) return whitelistPrice;
        return genesisPrice;
    }

    function updateSale(uint256 saleType, uint256 limit, uint256 liveIndex, bytes32 root) external adminOnly {
        require(saleType <= _lastSaleType || _lastSaleType + 1 == saleType, "Sale error");        
        Sale memory newSale;
        newSale.limit = limit;
        newSale.liveIndex = liveIndex;
        newSale.root = root;
        sales[saleType] = newSale;
        if(saleType > _lastSaleType) _lastSaleType = saleType;
    }

    function updateGenesisPrice(uint256 _price) external adminOnly {
        genesisPrice = _price;
    }

    function updateWhitelistPrice(uint256 _price) external adminOnly {
        whitelistPrice = _price;
    }

    function updateRoot(uint256 saleType, bytes32 _root) external adminOnly {
        sales[saleType].root = _root;
    }

    function addToWhitelist(uint256 saleType, address[] calldata to, bool[] calldata value) external adminOnly {
        uint256 total = to.length;
        for(uint256 i = 0; i < total;) {
            _whitelist[saleType][to[i]] = value[i];
            unchecked {
                i++;   
            }         
        }
    }
}