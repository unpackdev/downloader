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

contract cardclaim is Ownable, recovery {

    allocator           public cyal8r;
    address[]           public vaults;      // Founder,alpha,OG

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

    function numberOfValidators() external view returns (uint256) {
        return _valid8rs.length;
    }

    function addVault(address _vault) external onlyOwner {
        for (uint j = 0; j < vaults.length; j++) {
            require(vaults[j] != _vault,"Vault already added");
        }
        vaults.push(_vault);
    }

    function numberOfVaults() external view returns (uint256) {
        return vaults.length;
    }

    function setV8(uint position, bool enable ) external onlyOwner {
        _vvalid[position] = enable;
    }

    constructor(allocator _cyl, address[] memory _vaults, Ivalidator _v) {
        cyal8r = _cyl;
        _valid8rs.push(_v);
        _vvalid.push(true);
        vaults = _vaults;
    }

    function request(address _token, uint256 tokenId, uint256 position) external {
        bool    ok;
        uint256 card_type;

        IERC721Enumerable token = IERC721Enumerable(_token);
        require(token.ownerOf(tokenId) == msg.sender,"You do not own the token");
        require(position < _vvalid.length && _vvalid[position],"Plugin not valid");
        (card_type,ok) = _valid8rs[position].is_valid(address(token),tokenId);
        require(ok && (card_type < vaults.length),"Card not valid");
        address[] memory _vault = new address[](1);
        _vault[0] = vaults[card_type];
        bytes32 hash = cyal8r.getMeRandomCardsWithCallback(token, _vault , msg.sender);
        userhashes[msg.sender].push(hash);
    }

    function onERC721Received(address , address from, uint256 tokenId, bytes calldata data) external onlyApproved returns (bytes4) {
        revert("Please do not sent cards here");
    }

    function numberOfHashes(address user) external view returns (uint256){
        return userhashes[user].length;
    }

}