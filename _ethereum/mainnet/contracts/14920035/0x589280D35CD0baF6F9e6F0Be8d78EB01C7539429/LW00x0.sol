//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./LW77x7.sol";
import "./LTNT.sol";
import "./base64.sol";
import "./Rando.sol";
import "./LTNTFont.sol";


/**

          ___  ___      ___        __   __        __  
|     /\   |  |__  |\ |  |   |  | /  \ |__) |__/ /__` 
|___ /~~\  |  |___ | \|  |  .|/\| \__/ |  \ |  \ .__/ 
                                                      
"00x0", latent.works, 2022


*/


contract LW00x0 is ERC1155, ERC1155Supply, ERC1155Holder, Ownable, ReentrancyGuard, LTNTIssuer {

    // Orientation enum for artworks
    enum Orientation{LANDSCAPE, PORTRAIT}

    // Comp info
    struct Comp {
        uint id;
        address creator;
        string seed;
        string image;
        Orientation orientation;
        uint editions;
        uint available;
    }

    event CompCreated(uint indexed comp_id, address indexed creator);

    string public constant NAME = unicode"Latent Works · 00x0";
    string public constant DESCRIPTION = "latent.works";
    uint public constant PRICE = 0.07 ether;
    
    LTNT public immutable _ltnt;
    LW77x7 public immutable _77x7;
    LW77x7_LTNTIssuer public immutable _77x7_ltnt_issuer;
    LW00x0_Meta public immutable _00x0_meta;

 
    uint private _comp_ids;
    mapping(uint => uint[]) private _comp_works;
    mapping(uint => address) private _comp_creators;


    constructor(address seven7x7_, address seven7x7_ltnt_issuer_, address ltnt_) ERC1155("") {

        _77x7 = LW77x7(seven7x7_);
        _77x7_ltnt_issuer = LW77x7_LTNTIssuer(seven7x7_ltnt_issuer_);
        _ltnt = LTNT(ltnt_);

        LW00x0_Meta meta_ = new LW00x0_Meta(address(this), seven7x7_);
        _00x0_meta = LW00x0_Meta(address(meta_));

    }


    /// @dev require function to check if an address is the 77x7 contract
    function _req77x7Token(address address_) private view {
        require(address_ == address(_77x7), 'ONLY_77X7_ACCEPTED');
    }


    /// @dev return issuer information for LTNT passports
    function issuerInfo(uint, LTNT.Param memory param_) public view override returns(LTNT.IssuerInfo memory){

        return LTNT.IssuerInfo(
            '00x0', getImage(param_._uint, true, true)
        );

    }

    /// @dev override for supportsInterface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev recieves a batch of 77x7 works and creates a 00x from them as well as issues a LTNT for each work
    function onERC1155BatchReceived(address, address from_, uint[] memory ids_, uint[] memory, bytes memory) public override returns(bytes4){
        
        _req77x7Token(_msgSender());
        require(ids_.length > 1 && ids_.length <= 7, 'ID_COUNT_OUT_OF_RANGE');

        uint comp_id_ = _create(from_, ids_);
        uint id_;

        for(uint i = 0; i < ids_.length; i++){
            id_ = _77x7_ltnt_issuer.issueTo(from_, LTNT.Param(ids_[i], from_, '', true), true);
            _ltnt.stamp(id_, LTNT.Param(comp_id_, from_, '', false));
        }

        return super.onERC1155BatchReceived.selector;

    }
    
    /// @dev recieves a single 77x7 work and issues a LTNT for it
    function onERC1155Received(address, address from_, uint256 id_, uint256, bytes memory) public override returns(bytes4){
        _req77x7Token(_msgSender());
        _77x7_ltnt_issuer.issueTo(from_, LTNT.Param(id_, from_, '', false), true);
        return super.onERC1155Received.selector;
    }

    /// @dev internal function to create a comp for a given set of 77x7 works
    function _create(address for_, uint[] memory works_) private returns(uint) {

        require((works_.length > 1 && works_.length <= 7), "MIN_2_MAX_7_WORKS");

        _comp_ids++;
        _comp_works[_comp_ids] = works_;
        _comp_creators[_comp_ids] = for_;

        emit CompCreated(_comp_ids, for_);
        
        _mintFor(for_, _comp_ids);
        return _comp_ids;

    }

    /// @dev internal mint function
    function _mintFor(address for_, uint comp_id_) private {
        _mint(for_, comp_id_, 1, "");
    }

    /// @dev mint yeah
    function mint(uint comp_id_) public payable nonReentrant {

        require(msg.sender != _comp_creators[comp_id_], 'COMP_CREATOR');
        require(msg.value == PRICE, "INVALID_VALUE");
        require(getAvailable(comp_id_) > 0, "UNAVAILABLE");
        require(_comp_creators[comp_id_] != msg.sender, "NO_CREATOR_MINT");
        
        address owner_ = owner();
        uint each_ = msg.value / 2;
        (bool creator_sent_,) =  _comp_creators[comp_id_].call{value: each_}("");
        (bool owner_sent_,) =  owner_.call{value: each_}("");
        require((creator_sent_ && owner_sent_), "INTERNAL_ETHER_TX_FAILED");

        _mintFor(msg.sender, comp_id_);
        _ltnt.issueTo(msg.sender, LTNT.Param(comp_id_, msg.sender, '', false), true);

    }

    /// @dev get the number of total editions for a given comp
    function getEditions(uint comp_id_) public view returns(uint) {
        return _comp_works[comp_id_].length;
    }

    /// @dev get the creator adress of a given comp id
    function getCreator(uint comp_id_) public view returns(address){
        return _comp_creators[comp_id_];
    }

    /// @dev get the total available editions left for comp
    function getAvailable(uint comp_id_) public view returns(uint){
        return _comp_works[comp_id_].length - totalSupply(comp_id_);
    }


    /// @dev get the 77x7 work IDs used to create a given comp
    function getWorks(uint comp_id_) public view returns(uint[] memory){
        return _comp_works[comp_id_];
    }

    /// @dev get the image of a given comp
    function getImage(uint comp_id_, bool mark_, bool encode_) public view returns(string memory output_){
        require(totalSupply(comp_id_) > 0, 'DOES_NOT_EXIST');
        return _00x0_meta.getImage(comp_id_, mark_, encode_);
    }

    function getComps(uint limit_, uint page_, bool ascending_) public view returns(LW00x0.Comp[] memory){

        uint count_ = _comp_ids;

        if(limit_ < 1 && page_ < 1){
            limit_ = count_;
            page_ = 1;
        }

        LW00x0.Comp[] memory comps_ = new LW00x0.Comp[](limit_);
        uint i;

        if(ascending_){
            // ASCENDING
            uint id = page_ == 1 ? 1 : ((page_-1)*limit_)+1;
            while(id <= count_ && i < limit_){
                comps_[i] = getComp(id);
                ++i;
                ++id;
            }
        }
        else {
            /// DESCENDING
            uint id = page_ == 1 ? count_ : count_ - (limit_*(page_-1));
            while(id > 0 && i < limit_){
                comps_[i] = getComp(id);
                ++i;
                --id;
            }

        }

        return comps_;


    }


    /// @dev get the comp struct for a given comp ID
    function getComp(uint comp_id_) public view returns(LW00x0.Comp memory){

        return LW00x0.Comp(
            comp_id_,
            getCreator(comp_id_),
            _00x0_meta.getSeed(comp_id_, ''),
            getImage(comp_id_, true, true),
            _00x0_meta.getOrientation(comp_id_),
            getEditions(comp_id_),
            getAvailable(comp_id_)
        );

    }

    /// @dev get total number of comps created
    function getCompCount() public view returns(uint){
        return _comp_ids;
    }

    /// @dev return the metadata uri for a given url
    function uri(uint comp_id_) public view override returns(string memory){
        return _00x0_meta.getJSON(comp_id_);
    }


    // Required overrides

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Supply){
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal override (ERC1155) {
        super._mint(account, id, amount, data);
    }


    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override (ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }


    function _burn(address account, uint256 id, uint256 amount) internal override (ERC1155) {
        super._burn(account, id, amount);
    }


    function _burnBatch(address to, uint256[] memory ids, uint256[] memory amounts) internal override (ERC1155) {
        super._burnBatch(to, ids, amounts);
    }


}






contract LW00x0_Meta {

    LW00x0 private _00x0;
    LW77x7 private _77x7;
    
    string private _easing = 'keyTimes="0; 0.33; 0.66; 1" keySplines="0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1; 0.5 0 0.5 1;"';    
    string private _noise = 'data:@file/png;base64,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';

    // Compinfo for passing to the comp creator
    struct CompInfo {
        string id;
        string id_string;
        bool mark;
        string seed;
        string seed0;
        string seed1;
        string seed2;
        string seed3;
        uint[] works;
        bytes defs;
        bytes ani_elements;
        bytes elements;
        uint left;
        uint right;
        LW00x0.Orientation orientation;
        string width_string;
        string height_string;
        string[2] pos;
        uint start;
        uint last_left;
        uint last_right;
        bytes begin_t;
        bytes translate;
        bytes scale;
    }

    constructor(address zero0x0_, address seven7x7_){
        _00x0 = LW00x0(zero0x0_);
        _77x7 = LW77x7(seven7x7_);
    }

    /**
    
    SEEDS
    
     */
    function _generateSeed(address salt_, uint[] memory works_, string memory append_) private pure returns(string memory){
        uint salt_uint_ = (uint256(uint160(salt_)))/10000000000000000000000000000000000000;
        return string(abi.encodePacked(Strings.toString(salt_uint_+(works_[0]+works_[1])*(works_[0]+works_[1])*(77*works_.length)), append_));
    }

    function getSeed(uint comp_id_, string memory append_) public view returns(string memory){
        uint[] memory works_ = _00x0.getWorks(comp_id_);
        address salt_ = _00x0.getCreator(comp_id_);
        return _generateSeed(salt_, works_, append_);
    }


    /**
    
    ORIENTATION

     */
    function _generateOrientation(string memory seed_) private pure returns(LW00x0.Orientation){
        return Rando.number(seed_, 0, 99) > 50 ? LW00x0.Orientation.LANDSCAPE : LW00x0.Orientation.PORTRAIT;
    }

    function getOrientation(uint comp_id_) public view returns(LW00x0.Orientation){
        string memory seed_ = _generateSeed(_00x0.getCreator(comp_id_), _00x0.getWorks(comp_id_), '');
        return _generateOrientation(seed_);
    }


    /**
    
    COMPS
    
     */

    function _generateComp(address salt_, uint[] memory works_) private pure returns(CompInfo memory) {

        return CompInfo(
            '',
            '',
            false,
            _generateSeed(salt_, works_, ''),
            '',
            '',
            '',
            _generateSeed(salt_, works_, 'rand'),
            works_,
            '',
            '',
            '',
            0,
            0,
            _generateOrientation(_generateSeed(salt_, works_, '')),
            '',
            '',
            ['', ''],
            0,
            0,
            0,
            '',
            '',
            ''
        );

    }


    function getImage(uint comp_id_, bool mark_, bool encode_) public view returns(string memory) {

        CompInfo memory comp_ = _generateComp(_00x0.getCreator(comp_id_), _00x0.getWorks(comp_id_));

        comp_.id = Strings.toString(comp_id_);
        comp_.mark = mark_;

        return _generateImage(comp_, encode_);
        
    }

    function previewImage(address salt_, uint[] memory works_) public view returns(string memory){

        require((works_.length > 1 && works_.length <= 7), "MIN_2_MAX_7_WORKS");
        for(uint i = 0; i < works_.length; i++){
            require(_77x7.exists(works_[i]), 'WORK_DOES_NOT_EXIST');
        }

        CompInfo memory comp_ = _generateComp(salt_, works_);
        comp_.id = 'PRE';
        comp_.mark = true;

        return _generateImage(comp_, true);

    }

    function _generateImage(CompInfo memory comp_, bool encode_) private view returns(string memory){

        comp_.start = (700/comp_.works.length);
        comp_.last_left = Rando.number(comp_.seed1, comp_.start-100, comp_.start);
        comp_.last_right = Rando.number(comp_.seed2, comp_.start-100, comp_.start);
        
        comp_.pos[0] = Strings.toString(Rando.number(comp_.seed, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 800 : 500));
        comp_.pos[1] = Strings.toString(Rando.number(comp_.seed1, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 500 : 800));

        comp_.width_string = comp_.orientation == LW00x0.Orientation.LANDSCAPE ? '1000' : '700';
        comp_.height_string = comp_.orientation == LW00x0.Orientation.LANDSCAPE ? '700' : '1000';
        
        for(uint i = 0; i < comp_.works.length; i++) {
            
            comp_.seed0 = string(abi.encodePacked(comp_.seed, Strings.toString(i)));
            comp_.seed1 = string(abi.encodePacked(comp_.seed, abi.encodePacked(comp_.seed0, 'left')));
            comp_.seed2 = string(abi.encodePacked(comp_.seed, abi.encodePacked(comp_.seed0, 'right')));

            comp_.id_string = Strings.toString(i+1);
            
            comp_.left = Rando.number(comp_.seed1, comp_.last_left/10, 1000);
            comp_.right = Rando.number(comp_.seed2, comp_.last_right/2, 1000);
            
            comp_.defs = abi.encodePacked(comp_.defs,
            '<clipPath id="clip',comp_.id_string,'"><polygon points="0,',Strings.toString(comp_.last_left),' 0,',Strings.toString(comp_.left),' 1000,',Strings.toString(comp_.right),' 1000,',Strings.toString(comp_.last_right),'">',
            '</polygon></clipPath>');

            
            comp_.elements = abi.encodePacked(comp_.elements,
            '<rect fill="', _77x7.getColor(comp_.works[i], Rando.number(comp_.seed0, 1, 7)),'" y="0" x="0" height="1000" width="1000" clip-path="url(#clip',comp_.id_string,')">',
            '</rect>'
            );

            comp_.begin_t = abi.encodePacked(Strings.toString(Rando.number(comp_.seed1, 100, 700)),' ',Strings.toString(Rando.number(comp_.seed2, 100, 700)));
            comp_.translate = abi.encodePacked(comp_.begin_t, ';', Strings.toString(Rando.number(comp_.seed1, 10, 800)),' ', Strings.toString(Rando.number(comp_.seed2, 10, 800)),';', Strings.toString(Rando.number(comp_.seed2, 100, 1000)),' ', Strings.toString(Rando.number(comp_.seed1, 400, 800)),';',comp_.begin_t);
            comp_.scale = abi.encodePacked('1; 0.', Strings.toString(Rando.number(comp_.seed1, 1, 9)),'; 0.',Strings.toString(Rando.number(comp_.seed2, 1, 9)),'; 1');

            comp_.ani_elements = abi.encodePacked(comp_.ani_elements,
            '<rect fill="', _77x7.getColor(comp_.works[i], Rando.number(comp_.seed0, 1, 7)),'" y="0" x="0" height="1000" width="1000" clip-path="url(#clip',comp_.id_string,')">',
            '<animateTransform ',_easing,' attributeName="transform" type="scale" values="',comp_.scale,'" begin="0s" dur="',Strings.toString(Rando.number(comp_.seed2, 50, 100)),'s" repeatCount="indefinite"/>',
            '</rect>'
            );

            comp_.last_left = comp_.left;
            comp_.last_right = comp_.right;

        }

        comp_.pos[0] = Strings.toString(Rando.number(comp_.seed, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 800 : 500));
        comp_.pos[1] = Strings.toString(Rando.number(comp_.seed1, 100, comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 500 : 800));
        
        bytes memory output_ = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',comp_.width_string, ' ', comp_.height_string, '" preserveAspectRatio="xMinYMin meet">',
            '<defs>',
            '<pattern id="noise" x="0" y="0" width="51" height="51" patternUnits="userSpaceOnUse"><image opacity="0.2" width="51" height="51" href="',_noise,'"/></pattern>',
            '<g id="main" transform="translate(-5 -5) scale(1.2)" opacity="0.8">',
            comp_.elements,
            '</g>',
            '<g id="main-ani" transform="translate(-5 -5) scale(1.2)" opacity="0.8">',
            comp_.ani_elements,
            '</g>',
            '<filter id="blur" x="0" y="0"><feGaussianBlur in="SourceGraphic" stdDeviation="100"/></filter>',
            '<rect id="bg" height="',comp_.height_string,'" width="',comp_.width_string,'" x="0" y="0"/><clipPath id="clip"><use href="#bg"/></clipPath>',
            comp_.defs,
            '</defs>'
        );
        
        output_ = abi.encodePacked(
            output_,
            '<g clip-path="url(#clip)">',
            '<use href="#bg" fill="white"/>',
            '<use href="#bg" fill="',_77x7.getColor(comp_.works[0], 1),'" opacity="0.25"/>',
            '<use href="#main" filter="url(#blur)" transform="rotate(90, 500, 500)"/>',
            '<use href="#main-ani" filter="url(#blur)" transform="scale(0.',Strings.toString(Rando.number(comp_.seed0, 5, 9)),') rotate(90, 500, 500)"/>',
            '<use href="#main-ani" filter="url(#blur)" transform="scale(0.',Strings.toString(Rando.number(comp_.seed0, 3, 6)),') translate(',comp_.pos[0],', ',comp_.pos[1],')"/>',
            comp_.mark ? _getMark(comp_) : bytes(''),
            '<use href="#bg" fill="url(#noise)"/>',
            '</g>',
            '</svg>'
        );

        if(encode_)
            return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(output_)));

        return string(output_);

    }


    function _getMark(CompInfo memory comp_) private pure returns(bytes memory){
        
        bytes memory leading_zeroes_;
        if(bytes(comp_.id).length == 1)
            leading_zeroes_ = '00';
        else if(bytes(comp_.id).length == 2)
            leading_zeroes_ = '0';

        string memory lift_text_ = Strings.toString((comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 700 : 1000)-10);
        return abi.encodePacked('<style>.txt{font: normal 12px monospace;fill: white; letter-spacing:0.1em;}</style><rect width="115" height="30" x="-2" y="',Strings.toString((comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 700 : 1000)-28),'" fill="#000" class="box"></rect><text x="12" y="',lift_text_,'" class="txt">#', leading_zeroes_, comp_.id,unicode' · ', '00x0</text><text x="123" y="',lift_text_,'" class="txt">',comp_.seed0,'</text>');
        
    }


    function getJSON(uint comp_id_) public view returns(string memory){
        
        LW00x0.Comp memory comp_ = _00x0.getComp(comp_id_);
        bytes memory meta_ = abi.encodePacked(
        '{',
            '"name": "00x0 comp #',Strings.toString(comp_id_),'", ',
            '"description": "latent.works", ',
            '"image": "',comp_.image,'", '
            '"attributes": [',
            '{"trait_type": "orientation", "value":"',comp_.orientation == LW00x0.Orientation.LANDSCAPE ? 'Landscape' : 'Portrait','"},',
            '{"trait_type": "base", "value":',Strings.toString(_00x0.getWorks(comp_id_).length),'}',
            ']',
        '}');

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(meta_)));

    }

}

