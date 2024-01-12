// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//                        %%%%%%%((((/
//                  (((%%%####((#(((/(/////////
//               %%%(%((((%%((%((((((///(((///(////(
//             %%%((%((((%((((%(((((((((//((((/((((//((
//      @@%((((##%%%%%#%%(((%%((%((((((((//((((///(((///((
//    %%@@(#%(((((((#((%%%##%%##(%%((((((((//(((((/((###((///(***
//    @%((%%(((%((%%(((((((((((%%%%%################(((((///((///(
//    @%%%%((%%((%(((%((((%((((((///((((/((((//(((/(((((/(((//(((//
//     @##%%%%%%%(((%((((%((((%((((/(((((/((((/((((//((((/(((//((((
//     ,@@@@@@@@%%%%%####%##((%((//#(((((/(((((/##((///(((//((#(((&
//     @@@@@(((((@@@@@@%%%%%%%%%%%%%%%((/%%((((/%%%((%%%%%((@@@**@@
//   @@@@@@(((((((((@*@@@@@@@@@%%%%%%%%%%%%%%%%@@@@@@@@((((((******@@@
//   @@@@@((((((((((@@***(((((%#######%%%%%%%%((********************@@
// @@@@@##(((((((((((####(((((/**@@@@@@@@&&((((/  .((((********(((((@@
// @@@@@(((((((((((((((((((******@@(////////////////////@@@@@@@@@@@
// @@@@((((((((((((((((((((******@@@(/@@@@@@@@@@@@///@@@@@@@@@@///@
// @@@(((((((((((((((((*************@(@@@@@@@@@@@@/@/@@@@@@@@@@//@
// @@#((((((((((((((((((((((********@&(((@@@@@@(//@@/@@@@@@@@(/@@
// @@((((((((((((((((((((((**********@@@@@@@@@@@@@@@@(((((((/@
// ((((((((((((((((((((((**(*********@@@,,,   @@,,,,,%%%%&&&@@
// ((((((((((((((((((@((((*********@@,,,,,,,,@@,  @, @@@@@,,,@@@@@
// ((((((((((((((((((##@@&(******&&/,,,,@@,,,,/,..*,&@@/,/,,,@(**(@@%%
// ((((((((((((((((((((((@@@((((@@@,,,,,@ @@@@,,,,,,,,,,,,,,@******   @@
// (((((((((((((((((((((((@@@@@@@@@@,,,,@@     @@@@@@@@@@@@@********** @@
// ((((((((((((((((((@((((((@@@@@@@@@,,,,,@@@        @@@@@************* @@@
// ((((((((((((((((((#@@@(((((#@@@@@@@&&,,,//@%%%%%%%%%%@************** @@@
// ((((((((((((((((((((@@@@((((((@@@@@@@@@,,,,,,,,,,,@@@**************** @@@
// (((((((((((((((((((((((@@@@((((((@@@@@@@@@@@@@@@((********************@@@
// ((((((((((((((((((((((((@@@@@(((((((((((((((((((**********************@@@@
// ((((((((((((((((((((((((#@@@@&(((((((((((((((((*************************@@
//            __                                      __
//           / /_____  ___  ___ ____  ___  ___ ___ __/ /____
//          /  '_/ _ \/ _ \/ _ `/ _ \/ _ \/ _ `/ // / __(_-<
//         /_/\_\\___/_//_/\_, /\___/_//_/\_,_/\_,_/\__/___/  (TM)
//                        /___/

import "./ECDSA.sol";
import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Kongonauts is ERC721, ERC721Pausable, Ownable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    event StartingIndexSet(uint256 _value);
    event BaseUriUpdated(string _uri);
    event PreKeySet(address indexed _prekey);

    uint public constant MAX_PURCHASE = 10;
    uint public constant MAX_SUPPLY = 10000;
    uint public constant TOKEN_PRICE = 80000000000000000; //0.08 ETH

    bytes32 public constant PROVENANCE_HASH = 0x145778311c3a1e54ff6327df21f1c62a9abd4d425b89722db8e3e165793fbebc;

    uint public maxReserve;
    uint public reserveMinted;
    uint public startingIndex;
    string public baseURI;
    address public pkey;

    Counters.Counter private _tokenSupply;

    constructor(string memory initialBaseURI, uint _maxReserve) ERC721("Kongonauts", "KNGNT") {
        maxReserve = _maxReserve;

        baseURI = initialBaseURI;
        emit BaseUriUpdated(initialBaseURI);

        _setStartingIndex();
        _pause();
    }

    function _setStartingIndex() internal {
        require(startingIndex == 0, "Can only set startingIndex once");
        uint256 number = uint256(
          keccak256(
            abi.encodePacked(
              blockhash(block.number - 1),
              block.coinbase,
              block.difficulty,
              block.timestamp
            )
          )
        );
        startingIndex = (number % MAX_SUPPLY) + 1;
        emit StartingIndexSet(startingIndex);
    }

    function setPKey(address prekey) external onlyOwner {
        pkey = prekey;
        emit PreKeySet(prekey);
    }

    function setBaseURI(string memory newbaseURI) external onlyOwner {
        baseURI = newbaseURI;
        emit BaseUriUpdated(baseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function generateDigest(address sender) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    function generateEthDigest(address sender) public pure returns (bytes32) {
        bytes32 digest = generateDigest(sender);
        return digest.toEthSignedMessageHash();
    }

    function validateSignature(bytes32 digest, bytes memory signature) public view returns (bool) {
        return digest.recover(signature) == pkey;
    }

    function mint(address to, uint numberOfTokens, bytes memory signature, bool agreeTerms) public whenNotPaused payable {
        require(agreeTerms, "You must agree to the Terms of Service, Terms of Sale, and Privacy Policy");
        require(numberOfTokens <= MAX_PURCHASE, "Can only mint 10 tokens at a time.");
        require((totalSupply() + numberOfTokens) <= MAX_SUPPLY, "Purchase exceeds max supply.");
        require((TOKEN_PRICE * numberOfTokens) <= msg.value, "Ether value sent is not correct.");

        bytes32 digest = generateEthDigest(msg.sender);
        require(validateSignature(digest, signature), "Invalid signature");

        for (uint i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                safeMint(to);
            }
        }
    }

    function safeMint(address to) internal {
        _tokenSupply.increment();
        _safeMint(to, _tokenSupply.current());
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function reserve(address to, uint num) public onlyOwner {
        require(reserveMinted + num <= maxReserve, "R0"); // too many
        for (uint i = 0; i < num; i++) {
            _tokenSupply.increment();
            _safeMint(to, _tokenSupply.current());
        }
        reserveMinted += num;
    }

   function tokensOfOwner(address owner) public view returns(uint256[] memory tokens) {
        uint256 _balance = balanceOf(owner);
        tokens = new uint256[](_balance);
        uint j;
        for (uint i = 1; j < _balance; i++) {
            if (ownerOf(i) == owner) {
                tokens[j] = i;
                j++;
            }
        }
    }
}
