//                                                                                                  
//              :JJYJ~    :!       !.     ^7!.   ~7!!!!!7~   .^        ~!.     ::.   ~~          ..   
//      75J.    5@7.^5P^  .JG!.   5B.    PB!J#^  ~!!?@?!!!  !GPB~    75J!.   !GYJ55~ ~JB^  ^P. 7Y5!   
//    :BY^.     J@J:::P&.   ^JPJ.Y#.     #P.?@^     ^@:    5B^ 5#   ~&5~    .&?   !@~  7#!^&? ^@5:    
//    PG        ~@GP&B?^      .J&B:      P#JJ^      ^@^   ~@:  J&.    ^Y#:  ~@~   5B.   ~&&?   :755:  
//   :@!        .#G :JG?^      ^&~       PB         ^@^   :&J^J#~    .^J&:   7PYJGJ.     B#.   ..7@7  
//   .G57~^~.    JP   :77     :&J        ?@.        :Y:    ^??J^     ?Y!.      ::.      !@^   :5Y?^   
//     :7??J^                 ~5         .!                                             ??                                                                                                                                                                                                                                              
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB&&@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&PY555P#@@@@@@@@@
//@@@@@@@@@@@@@#P55PB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PB@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G555Y5YY5B@@@@@@@@
//@@@@@@@@@@@@Y:....:^~!?5#@@@@@@@@@@@@@@@@@@@@5JJJ?GPG?7?J&@@@@@@@@@@@@@@@@@@@@@@B5Y5YY5YY5YY5&@@@@@@
//@@@@@@@@@@@Y.:::::^^^:..:P@@@@@@@@@@@@@@@@@@@!^^^^Y55!^^~#@@@@@@@@@@@@@@@@@&#BG5J?777!!77!?JJ5@@@@@@
//@@@@@@@@@@G::^^^^~~~~~^:::G@@@@@@@@@@@@@@@@@@777?!!!?~~^!&@@@@@@@@@@@@@@@@@PJJJJ?!!!?^?7!7!YJJB@@@@@
//@@@@@@@@@#^::~~!!!~!!~~:::^&@@@@@@@@@@@@@@@G5~!!!7?!!~~^?@@@@@@@@@@@@@@@@@@5JJJJ!^~~~~7?!~~?JJG@@@@@
//@@@@@@@@@7.::^7!~7!?!7^::::B@@@@@@@@@@@@@@@7~~~~~~!YP#G~Y@@@@@@@@@@@@@@@@@@PJJY?^~~^?Y!Y?7^!JJG@@@@@
//@@@@@@@#7.:::^~~~?7J7^~^:.^&@@@@@@@@@@@@@@@GP!~~~~P@@@P~B@@@@@@@@@@@@@@@@@@GJJY7^~~~~!?YY?~~JJ#@@@@@
//@@@@@@Y:.:::::^~~!?55!^:.:G@@@@@@@@@@@@@@@@@&~~~^G@@@@?^#@@@@@@@@@@@@@@@@@@#JJY7~~~~^7Y@@@G!?5@@@@@@
//@@@@@&?^..::::^~~~B@@7^?YB@@@@@@@@@@@@@@@@@@G^~~~B@@@@G!&@@@@@@@@@@@@@@@@@@@PJY7^~~~^?P@@@G77P@@@@@@
//@@@@@@@&P?!::^~!~~!J7^~&@@@@@@@@@@@@@@@@@@@@P^^^^?&@@@P7@@@@@@@@@@@@@@@@@@@@PJJ!~!~^~!?B@@Y?J5#&@@@@
//@@@@@@@@@@J^~~~!777777G@@@@@@@@@@@@@@@@@@@@@G7???~!J5?^7@@@@@@@@@@@@@@@@@@@GJJY?~!77~^~7J5GBYJ5&@@@@
//@@@@@@@@@@J^~~~~~~?@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~^Y@&BB@@@@@@@@@@@@@@@@@@@&BB&Y^~^Y#PPGB&@@&B@@@@@@
//@@@@@@@@@@J^~~~~~~~#@@@@@@@@@@@@@@@@@@@@@@@@@@@@J^^Y@@@@@@@@@@@@@@@@@@@@@@@@@@@7^~^5@@@@@@@@@@@@@@@@
//@@@@@@@@@@Y^~~~~~~^B@@@@@@@@@@@@@@@@@@@@@@@@@@@@7^^Y@@@@@@@@@@@@@@@@@@@@@@@@@@&!^~^G@@@@@@@@@@@@@@@@

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract OOOOOOOO is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0 ether;
    uint256 public maxSupply = 1001;
    uint256 public maxMintAmount = 1;
    uint256 public maxperwallet = 1;
    bool public paused = false;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;
    mapping(address => uint256) public mintedWallets;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        mint(msg.sender, 1);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
        require(mintedWallets[msg.sender] <= maxperwallet, 'exceeds max per wallet');
        mintedWallets[msg.sender] += maxperwallet;

        if (msg.sender != owner()) {
                 {
                    //general public
                    require(msg.value >= cost * _mintAmount);
                
            }
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
