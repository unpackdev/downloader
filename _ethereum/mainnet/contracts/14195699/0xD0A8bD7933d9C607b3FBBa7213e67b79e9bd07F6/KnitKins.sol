//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

 _   __ _   _ _____ _____   _   _______ _   _  _____
| | / /| \ | |_   _|_   _| | | / /_   _| \ | |/  ___|
| |/ / |  \| | | |   | |   | |/ /  | | |  \| |\ `--.
|    \ | . ` | | |   | |   |    \  | | | . ` | `--. \
| |\  \| |\  |_| |_  | |   | |\  \_| |_| |\  |/\__/ /
\_| \_/\_| \_/\___/  \_/   \_| \_/\___/\_| \_/\____/

                                                         %%%%%%
                                               %%%              #
                                           %%       %%%%%%%%%%%%
                                          %,   %
                 %%%%%%%%%%%             % , %
           %%(  %%       ,      %%       %   %%
        %%    (%      ,     ,,,,   %%     %%   %
      %      %       ,   ,  ,     ,   %     %,   %
     %,      %       ,             ,    %     %%  ,%%
   %         %       ,     ,      ,      %      %%   ,%
   %         %        ,                   %        %    %
  %%  ,       %        ,                 ,%          %%   %
  %%  % %     %#         % %           , %            %   %
  %,%%    %      %%     %    %,  ,,,,,    %             %,  %
   %,%    %         %   %    %   ,      , %     %%%%%.    %%
    % , %%   ,         %%   %   ,   ,    %, ,        %%%
      %% ,  %%  ,           %%%     , %%
          %%%%%%%%%%%%%%%%%%%%%%%%%%

*/

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract KnitKins is ERC721A, Ownable, Pausable {
    using SafeMath for uint256;

    event PermanentURI(string _value, uint256 indexed _id);

    uint public constant MAX_SUPPLY = 10000;
    uint public constant PRICE = 0.05 ether;
    uint public constant MAX_PER_MINT = 10;
    uint public constant MAX_RESERVE_SUPPLY = 100;

    string public _contractBaseURI;

    constructor(string memory baseURI) ERC721A("Knit Kins", "KNITKINS") {
        _contractBaseURI = baseURI;
        _pause();
    }

    // reserve MAX_RESERVE_SUPPLY for promotional purposes
    function reserveNFTs(address to, uint256 quantity) external onlyOwner {
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(totalMinted.add(quantity) <= MAX_RESERVE_SUPPLY, "No more promo NFTs left");
        _safeMint(to, quantity);
        lockMetadata(quantity);
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(quantity <= MAX_PER_MINT, "Cannot mint that many at once");
        require(totalMinted.add(quantity) < MAX_SUPPLY, "Not enough NFTs left to mint");
        require(PRICE * quantity <= msg.value, "Insufficient funds sent");

        _safeMint(msg.sender, quantity);
        lockMetadata(quantity);
    }

    function lockMetadata(uint256 quantity) internal {
        for (uint256 i = quantity; i > 0; i--) {
            uint256 tid = totalSupply() - i;
            emit PermanentURI(tokenURI(tid), tid);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://knitkins.com/opensea/contract_metadata.json";
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }
}
