// SPDX-License-Identifier: MIT

/*
:::::::::::::::::::::::::::::ヽヽヽヽ:::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::☆:::::::.:::::::::ヽヽヽヽヽ:::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::,'  ヽ.::::::::ヽヽヽ::::::::,.::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::。::/       ヽ:::::::::ヽヽ ::: ／   ヽ:::::::☆:::::::::::::☆::::::::☆::::::
::::::::::::::::::/           ヽ:::::::::☆::/         ヽ::::::::::::::::::::::::::::::::::::
::::::::::::::::;'              ｀--ｰｰｰｰｰ-く .         ',:::::::::::::::::::::::::::::::::
:::::::::☆:::::/                                       ',:::::::::::::::::::::::::::::::::
::::::::::::::/                                          ,:::::::::::::::::。:::::::::::::
:::::::::::::/                                            ,::::::::::::::。::::::::::::::::
::::::::::::;'                                            ::::::。:::::::::::::::::::::::::
:::。:::::: /                    , ＿＿＿＿＿＿             j::::::::::::::。::::::::::::::::
:::::::::: j               ' ´                   ｀ ヽ.      ,:::::::::::。::::::::::::::::::
::::::::::!              ´                           ヽ      ,:::::::::☆:::::::::::::::::::
::::::::: !             ´      ＿                ＿   ヽ     !::::::::::::::::::::::::::::::
::::::::: !            |  γ  =（   ヽ         : ' =::（ ヽ|     !:::::::::::::::::::::::::::::
::::::::: !            | 〈 ん:::☆:j j       ! ん:☆:::ﾊ       ::::::::::::::::::::::::::::::
::::::::: !            |  弋:::::.ﾉ ﾉ        ヾ:::::ﾉ ﾉ |     ::::::::::::::::::::::::::::::
:::::::::::'           |    ゝ  -  '     人    -    '  ﾉ     j::::::::::::::::::::::::::::::
:::::::::::,            ヽ                            ,     j::::☆::::::::::::::::::::::::::
::::::::::::,            ' ､                      , ／     ﾉ::::::::::::::::::::::::::::::::
::::::::::::::＼             ｰ--------------- '         ,':::::::::::::::::::::::::::::::::
::::☆:::::::::::ヽ                                    ／:::::::::::::::::::::::::::::::::::
:::::::::::::::::::7                :::::::::::::::＜::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::r´                   :::::::::::::ヽ::::::::::::::::::::::::::::::::::::
::::::::::::::::::/                               :::::ヽ::::::::::::::::::::::::::::::::::
*/

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";            

contract HonoraryTubbyCats is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private _baseURIextended;

    constructor() ERC721("Honorary Tubby Cats", "HTUBBY") {
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function mint(uint256 amountToMint) public onlyOwner {
        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
}