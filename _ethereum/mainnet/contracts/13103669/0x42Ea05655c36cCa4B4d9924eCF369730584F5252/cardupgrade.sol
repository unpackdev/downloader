pragma solidity ^0.7.5;

import "./IERC721Receiver.sol";
import "./allocator.sol";
import "./Ivalidator.sol";
import  "../recovery/recovery.sol";

import "./console.sol";

//
// function setTrait(uint16 traitID, uint16 tokenId, bool _value) public onlyAllowedOrSpecificTraitController(traitID) {
// function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result) {
// traits 0 - 50

contract cardupgrade is Ownable, recovery {

    allocator           public cyal8r;
    address[]           public vaults;      // Founder,alpha,OG
    address             public redeemVault;

    Ivalidator[]        public _valid8rs;
    bool[]              public _vvalid;

    mapping(address => bytes32[]) public userhashes;

    mapping (address=>bool) public approvedTokens;

    modifier onlyApproved() {
        require(approvedTokens[msg.sender],"Unauthorised token");
        _;
    }

    function setToken(address token, bool status) external onlyOwner {
        approvedTokens[token] = status;
    }

    function addValidator(Ivalidator _v8) external onlyOwner {
        _valid8rs.push(_v8);
        _vvalid.push(true);
    }

    function setV8(uint position, bool enable ) external onlyOwner {
        _vvalid[position] = enable;
    }

    constructor(allocator _cyl, address[] memory _vaults, Ivalidator _v, address _redeemVault) {
        cyal8r = _cyl;
        _valid8rs.push(_v);
        _vvalid.push(true);
        vaults = _vaults;
        redeemVault = _redeemVault;
    }

    function onERC721Received(address , address from, uint256 tokenId, bytes calldata data) external onlyApproved returns (bytes4) {
        bool    ok;
        uint256 card_type;
        uint256 position = 0;
        if (data.length > 0) {
            require(data.length == 1,"Invalid data length");
            position = uint256(uint8(data[0]));
        }
        require(position < _vvalid.length && _vvalid[position],"Plugin not valid");
        IERC721Enumerable token = IERC721Enumerable(msg.sender);

        console.log("about to transfer");
        token.safeTransferFrom(address(this),redeemVault, tokenId);
        console.log("transferred");
        (card_type,ok) = _valid8rs[position].is_valid(address(token),tokenId);
        console.log("card type",card_type);
        require(ok && (card_type < vaults.length),"Card not valid");
        console.log("stage 1");
        address[] memory _vault = new address[](1);
        console.log("stage 2");
        _vault[0] = vaults[card_type];
        console.log("about to cyal8r with ", _vault[0], from);
        bytes32 hash = cyal8r.getMeRandomCardsWithCallback(token, _vault , from);
        userhashes[from].push(hash);
        return IERC721Receiver.onERC721Received.selector;
    }

    function numberOfHashes(address user) external view returns (uint256){
        return userhashes[user].length;
    }

}