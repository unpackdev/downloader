// SPDX-License-Identifier: MIT
//******************************************************************************************************************************************************
//*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////*///////////////////////////////////////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/////////////////////
//*///////////////////////////////*///////////////////////////////*///////////////////////////////*///////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/////////////////////
//*///////////////////////////////////////////&/////////////&/////*///////////////////////////////////////////////////////////////*/////////////////////
//*////////////////////////@@@@@//////////////@@////////////@@////////////////////////////////////////////&@@/////////////////////*/////////////////////
//*///////////////*///@@@////@@@@@@///////////@@@/*/////////@@@///*//////////////(*///////@@@@@@#/*///////@@@(/(@@*////@@@@@//////*///////////////*/////
//*//////////////////@@/////////@%@/@@/////////@@///////////@@@///@@/////@@@/@@//@@////@@@&/////@@@&///@@@@///@@#/@@/@//////%////@@@///@////////////////
//*/////////////////@@@/////////&@@@@/&@@@@@(///@@@@@@@@@////@@(/@@///@@@@/////@@@/////@@@////////@@@@@@////////@@@@@(///////////@@@////////////////////
//*////////////////@@@@/////////@@@@@@##@////%@@@@////////@@@/@&//@#//@@@///////@@@////@@@////////@@@/@/////////@@&///@@@@@@@/////@@@@//////////////////
//*/////////////////@@@&///////@@%@@@@//////////@@@////////@@/@@//*@///@@///////@@@////@%@//////(@@#@/@////////@@///////////@@////*#@@@#////////////////
//*///////////////////@@@@@@@/////@@@@/////////@@@@&///////@@/@@///@@///@#/////@@@@/////@@@@@@@@@///@@@@////@@@@////&@/////%@@////*///@@////////////////
//*////////////////@///////////////@@//////////@@@@%////@@@@@/@@//*/@(///@/////@@/@(////@@////////////@@@@@@//@//////@@@@@@&/#@@//*/@@@(////////////////
//*////////////////@@/////////////@@@@&//////&@@//@@@@@@(/////@@/////@////////////@@////@@///////////////////@//////////////////%@@@@@//////////////////
//*///////*///////*//@@@//*//////%@@//@@@//@@@////@%//////*////@@/*///////*///////*//////@@///////*///////*///////*///////*///////*///////*///////*/////
//*///////////////////////#@@@@@@@(//////////////////////////////////////////////////////&@///////////////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////*///////////////////////@///////////////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/////////////////////
//*///////////////////////////////*///////////////////////////////*///////////////////////////////*///////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////*///////////////////////////////////////////////////////////////*/////////////////////
//*///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/////////////////////
//*///////////////*///////////////*///////////////*///////////////*///////////////*///////////////*///////////////*///////////////*///////////////*/////

pragma solidity ^0.8.0;

import "ERC721A.sol";
import "IERC721.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Address.sol";
import "Math.sol";

struct PassConfig {
    string bEussieUAREL;
    uint256 maxSupply;
    uint256 friieMiinttss;
    uint256 scheeapiarPrizzc;
    uint256 stndrrdPrizzc;
    address payable zaieezVuleliete;
    IERC721 goblinsAddress;
    address initialMintWallet;
    uint256 initialMintAmount;
}

contract GoblinPass is ERC721A, Ownable, ReentrancyGuard {
    using Address for address payable;

    error NottNoffPissLefd();
    error NottEenuffEetheel();

    string public bEussieUAREL;
    uint256 public maxSupply;
    uint256 public friieMiinttss;
    uint256 public scheeapiarPrizzc;
    uint256 public stndrrdPrizzc;
    address payable public zaieezVuleliete;
    IERC721 goblinz;
    mapping(address => uint256) public kleaeiemide;

    constructor(PassConfig memory config) ERC721A("GoblinPass", "GOBLINPASS") {
        ssiteBEussieUAREL(config.bEussieUAREL);
        maxSupply = config.maxSupply;
        setFriieMiinttss(config.friieMiinttss);
        setPrizzcs(config.scheeapiarPrizzc, config.stndrrdPrizzc);
        setZaieezVuleliete(config.zaieezVuleliete);
        goblinz = config.goblinsAddress;

        _safeMint(config.initialMintWallet, config.initialMintAmount);
    }

    function ssiteBEussieUAREL(string memory ooarle) public onlyOwner {
        bEussieUAREL = ooarle;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            string(abi.encodePacked(bEussieUAREL, _toString(tokenId), ".json"));
    }

    function setZaieezVuleliete(address payable knouuVuleliete)
        public
        onlyOwner
    {
        require(knouuVuleliete != address(0), "Sales wallet can't be 0x0");
        zaieezVuleliete = knouuVuleliete;
    }

    function gietScooztt(uint256 _pissAmount, address hoo)
        public
        returns (uint256 cost, uint256 phreeePiss)
    {
        cost = _pissAmount * stndrrdPrizzc;
        uint256 amountGoblins = goblinz.balanceOf(hoo);
        phreeePiss = 0;

        if (amountGoblins > 0) {
            if (kleaeiemide[hoo] > amountGoblins) {
                amountGoblins = 0;
            } else {
                amountGoblins -= kleaeiemide[hoo];
            }

            phreeePiss = Math.min(amountGoblins, _pissAmount);
            if (friieMiinttss < phreeePiss) {
                phreeePiss = friieMiinttss;
            }
            cost = scheeapiarPrizzc * (_pissAmount - phreeePiss);
        }
    }

    function emeinTtPas(uint256 amoOountTt) external payable nonReentrant {
        (uint256 _kosst, uint256 phreeePiss) = gietScooztt(
            amoOountTt,
            msg.sender
        );
        if (phreeePiss > 0) {
            friieMiinttss -= phreeePiss;
            kleaeiemide[msg.sender] += phreeePiss;
        }

        if (amoOountTt + totalSupply() > maxSupply) revert NottNoffPissLefd();
        if (_kosst > msg.value) revert NottEenuffEetheel();

        uint256 ereemaiinyngj = msg.value - _kosst;
        zaieezVuleliete.sendValue(_kosst);
        if (ereemaiinyngj > 0) {
            payable(msg.sender).sendValue(ereemaiinyngj);
        }

        _safeMint(msg.sender, amoOountTt);
    }

    function gittePatogjerizz()
        public
        view
        returns (
            uint256 _maxSupply,
            uint256 _totalSupply,
            uint256 _friieMiinttss
        )
    {
        return (maxSupply, totalSupply(), friieMiinttss);
    }

    function setPrizzcs(uint256 _scheeapiarPrizzc, uint256 _stndrrdPrizzc)
        public
        onlyOwner
    {
        require(_scheeapiarPrizzc > 0);
        require(_stndrrdPrizzc > 0);
        require(_scheeapiarPrizzc < _stndrrdPrizzc, "A < B");
        scheeapiarPrizzc = _scheeapiarPrizzc;
        stndrrdPrizzc = _stndrrdPrizzc;
    }

    function setFriieMiinttss(uint256 _friieMiinttss) public onlyOwner {
        friieMiinttss = _friieMiinttss;
    }
}
