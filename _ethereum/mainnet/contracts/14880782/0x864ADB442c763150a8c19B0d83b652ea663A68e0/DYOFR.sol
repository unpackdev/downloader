// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

import "./IDYOFR.sol";
import "./ERC721AWithRoyalties.sol";
import "./Ownable.sol";

    error InvalidEthereumValue();
    error ItAintGotNoGasInIt();
    error YouTried();
    error RefundFailed();

/*
    8888888b. Y88b   d88P  .d88888b.  8888888888 8888888b.
    888  "Y88b Y88b d88P  d88P" "Y88b 888        888   Y88b
    888    888  Y88o88P   888     888 888        888    888
    888    888   Y888P    888     888 8888888    888   d88P
    888    888    888     888     888 888        8888888P"
    888    888    888     888     888 888        888 T88b
    888  .d88P    888     Y88b. .d88P 888        888  T88b
    8888888P"     888      "Y88888P"  888        888   T88b
*/

//  @title   DYOFR - Do Your Own Fucking Research
//  @author  DoYourOwnFuckingResearch.eth
//  @dev     Made to fool tools that rely on honest implementations of ERC721.
//  @notice  DYOFR. An acronym to live by. Reveal Jun 2 2022. Tokens serve as a full-pass towards the next generation of tool for dominating the blockchain(s).
contract DYOFR is ERC721AWithRoyalties {

    uint256 public constant     _MAX_SUPPLY = 2000;
    uint256 public constant     _PRICE      = 0.04 ether;

    bool public                 revealed;
    bool private                burned;

    string private              baseURI;
    string private constant     imageURI    = "ipfs://QmQo4vaHjeivMqKeUqj1ZUXKBssHKyuoWpTRgti7GQFRjP";

    mapping(address => bool)    fnf;
    mapping(address => uint256) mistakes;
    mapping(uint256 => address) indices;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokens;

    constructor() ERC721AWithRoyalties(
        "DYOFR",
        "DYOFR",
        tx.origin,500
    ){}

    function mint(
        uint256 quantity
    ) external payable {
        if (mintInternal(quantity,_PRICE) && !burned) emitFauxTransfers(quantity);
    }

    function mint(
        uint256 quantity,
        uint256 price
    ) external payable {
        if (!fnf[msg.sender]) revert YouTried();
        if (mintInternal(quantity,price) && !burned) emitFauxTransfers(quantity);
    }

    function mintInternal(
        uint256 quantity,
        uint256 price
    ) internal returns(bool) {
        if (msg.value < price * quantity && msg.sender != owner()) revert InvalidEthereumValue();
        if (_totalMinted() + quantity > _MAX_SUPPLY) {
            mistakes[msg.sender] += msg.value;
            return false;
        }else{
            _mint(msg.sender,quantity);
            return true;
        }
    }

    function iSentATransactionLate() external {
        if ( mistakes[msg.sender] == 0 ) revert YouTried();
        if( !refund(mistakes[msg.sender] - 0.005 ether) ) revert RefundFailed();
        mistakes[msg.sender] = 0;
    }

    function iHavePaperHands(
        uint256 tokenId
    ) external {
        if ( _ownerOf(tokenId) != msg.sender || fnf[msg.sender] ) revert YouTried();
        if( !refund(_PRICE/2) ) revert RefundFailed();
        _burn(tokenId,false);
    }

    function refund(
        uint256 _refund
    ) internal returns (bool){
        if (msg.sender != tx.origin) revert YouTried();
        if ( address(this).balance < _refund ) revert ItAintGotNoGasInIt();
        (bool success,) = address(msg.sender).call{
        value : _refund
        }("");
        return success;
    }

    function emitFauxTransfers(
        uint256 quantity
    ) internal {
        unchecked{
            uint256 tokenId = _MAX_SUPPLY+(_totalMinted()-quantity)+_startTokenId();
            for(uint256 q = 0; q < quantity; q++){
                address faux = fauxAddress(msg.sender,tokenId+q);
                uint256 _tokenId = tokenId+(q*3);
                for (uint256 i = 0; i < 3; i++){
                    emitTransfer(msg.sender,_tokenId+i);
                    emitTransfer(msg.sender,faux,_tokenId+i);
                }
            }
        }
    }

    function emitTransfer(
        address to,
        uint256 tokenId
    ) internal {
        emitTransfer(0x0000000000000000000000000000000000000000,to,tokenId);
    }

    function totalSupply() public view override returns (uint256) {
        if ( !burned && _totalMinted() < _MAX_SUPPLY ) return (_totalMinted()*4);
        return _totalSupply();
    }

    function balanceOf(
        address owner
    ) public view override returns (uint256) {
        uint256 balance = _balanceOf(owner);
        if ( !burned && _totalMinted() < _MAX_SUPPLY ){
            balance = balance*4;
            if ( balances[owner] > 0 ){
                balance += balances[owner];
            }
        }
        return balance;
    }

    function actualTokenId(
        uint256 tokenId
    ) internal pure returns (uint256) {
        uint256 t = (tokenId - _MAX_SUPPLY);
        uint256 d = t % 3;
        if ( d == 0 ){
            d = 3;
        }
        return ((t - d)/3) + _startTokenId();
    }

    function ownerOf(
        uint256 tokenId
    ) public view override returns (address) {
        if ( !burned && _totalMinted() < _MAX_SUPPLY ){
            if (tokenId >= _MAX_SUPPLY * 4){
                return tokens[tokenId];
            } else if (tokenId > _MAX_SUPPLY && tokenId <= _MAX_SUPPLY + (_totalMinted()*3)){
                uint256 _actualTokenId = actualTokenId(tokenId);
                return fauxAddress(_ownerOf(_actualTokenId),_actualTokenId);
            }
        }
        return _ownerOf(tokenId);
    }

    function fauxAddress(
        address owner,
        uint256 tokenId
    ) internal pure returns (address){
        return address(bytes20(sha256(abi.encodePacked(owner,tokenId))));
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if ( _totalMinted() >= _MAX_SUPPLY || burned ){
            if ( !_exists(tokenId) ) revert URIQueryForNonexistentToken();
        }else{
            if ( ownerOf(tokenId) == address(0) ) revert URIQueryForNonexistentToken();
        }
        if( !revealed ){
            return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    _encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "DYOFR Pass #',
                                    _toString(tokenId),
                                    '", "description": "DYOFR. An acronym to live by. Reveal Jun 10 2022. Tokens serve as a full-access-pass towards the next generation of tools for dominating the blockchain(s).", "image": "',imageURI,'"}'
                                )
                            )
                        )
                    )
                )
            );
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    function setBaseURI(
        string calldata _baseURI,
        bool _revealed
    ) external onlyOwner {
        baseURI = _baseURI;
        revealed = _revealed;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function burnFauxTokens() external onlyOwner {
        burned = true;
        for(uint i = _MAX_SUPPLY+_startTokenId(); i <= _MAX_SUPPLY+(_totalMinted()*3); i++ ){
            emitTransfer(address(this),0x000000000000000000000000000000000000dEaD,i);
        }
    }

    function withdraw() external onlyOwner {
        (bool success,) = address(owner()).call{
        value : address(this).balance
        }("");
        if (!success) revert("Failed");
    }

    function setFNF(
        address[] calldata _fnf,
        bool allowed
    ) external onlyOwner {
        for(uint256 i = 0; i < _fnf.length; i++){
            fnf[_fnf[i]] = allowed;
        }
    }

    function _encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
            mstore(result, encodedLen)

        // prepare the lookup table
            let tablePtr := add(table, 1)

        // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

        // result ptr, jump over length
            let resultPtr := add(result, 32)

        // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

            // read 3 bytes
                let input := mload(dataPtr)

            // write 4 characters
                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                resultPtr,
                shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

}
