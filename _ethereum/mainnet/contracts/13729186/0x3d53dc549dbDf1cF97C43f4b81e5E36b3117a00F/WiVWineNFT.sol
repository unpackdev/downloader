// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";

abstract contract WiVWineNFT is ERC721 {
    using Counters for Counters.Counter;

    enum Burn_Type { UNMINT, REDEEM }
    enum Wine_Type { RED, WHITE, SPARKLING, CHAMPAGNE, ROSE, FORTIFIED, SWEET, SPIRIT, WHISKY, SPECIAL, OTHER }

    // Wine details
    struct Lot {
        string brand_name;
        string region;
        Wine_Type wine_type;
        uint256 year;
        string production_country;
        string producer;
        bool exist;
        uint256 bottle_quantity;
    }

    mapping( uint256 => Lot ) internal lots;

    Counters.Counter internal _tokenIdCounter;

    event LotMinted(uint256 indexed _lot_id, uint256 indexed _process_id );
    event LotDestroyed(uint256 indexed _lot_id);
    event LotRedeemed(uint256 indexed _lot_id);
    error MintingError( uint256 _process_id, string _error );
    error BurningError( uint256 _product_id, string _error );

    /****************************************
        Part that handles LOT
    ****************************************/

    function mintLot( uint256 _process_id,
                     address _owner_address,
                     string memory _brand_name,
                     string memory _region,
                     uint256 _wine_type,
                     uint256 _year,
                     string memory _production_country,
                     string memory _producer,
                     uint256 _bottle_unit,
                     string memory _uri ) public virtual {
    }

    /****************************************
        Part that handles PRODUCT
    ****************************************/

    function getProductInfo(uint256 _product_id)
        public view returns(string memory,
                            string memory,
                            uint256,
                            uint256,
                            string memory,
                            string memory,
                            uint256) {
        if( lots[_product_id].exist == true ) {
            Lot memory tmp_lot = lots[_product_id];
            return( tmp_lot.brand_name,
                    tmp_lot.region,
                    uint256(tmp_lot.wine_type),
                    tmp_lot.year,
                    tmp_lot.production_country,
                    tmp_lot.producer,
                    tmp_lot.bottle_quantity
                    );
        } else {
            revert("This product does not exist");
        }
    }

    function burnLot( uint256 _product_id, uint256 _burn_type) public virtual {
    }
}
