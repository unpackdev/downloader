// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./OptimizedERC721Enumerable.sol";

/*
....................................................................................................
....................................................................................................
....................................................................................................
..................------------......................................................................
...........-..----------------------://+oossssssoo++/::-............................................
......-.----------------------:+syyyso+/::-------:/++osyys-.........................................
....----------------------:+yys+:.`                    `.yh-........................................
..---------------------:+yyo-`                           `hh........................................
----------------------sho-                                `dy.......................................
---------------------dy.                                   .mo-.....................................
------------------:sdM.                                     -Nmhs:..................................
-----------------ymosm                                       /N//hd+................................
---------------:my..hy                 `-://+ooossssooo++.    om+.:dh...............................
---------------dh...N+         `-/oyyyyso+/::-........--:.     .+hhodd..............................
--------------/M:..-M-     ./syyo/-`                              .+hMs.............................
--------------+M.../M`   :hs/.`                                      -sdo...........................
--------------:M/..ym    ``                                         ``.:hmo.........................
---------------ym:hy.                             ``.--::/+ooosssyhmhhyyydNd........................
----------------dmo`                   `.--:+oossyyyssoo++/:::----:Ny//oydy:........................
---------------om:             `.-/+osyysso+/::--................../Nhhhsssso:......................
--------------sd-       ``.:+oyyss+/:-..............-:/+++++::-.....sN:+m+::/ds.....................
-------------yd.   `.-+oyyso/:-.....-+++/-......-/syhyssoosssyhyo:..-M/:/....:/......-:++/-.........
------------sm-`:+shdNh:...........odo/+yd:...-sdy+:--/dmmmmo--/ohh/.No............-shs++ohh-.......
-----------+Mhhhyso+/hd............s/....o/..+ms:-----oNMMMMy-----+mydd...........om+......M+.......
-----------mms+//////yM.....................sm/--------/ymds-::----:dddh.........yd-......yd-......-
-----------ymyo+////oN+....................+N/-----:ydhhdyshdhhmo---:MoN+.......ym-...../my-......--
------------:oyhhdddNh.....................dy------dh----/+:---oM:---dydy......oN-.....sN/.......---
--------------------No.....................ms------M+-/ooo+/---sN----msdy.....:N/.....oNshh/....----
--------------------No.....................yd------Nmhs+++oydo:Ns---oN:N+.....dh-::-..d/../dy.------
--------------------hh.....................-my-----ym:......:dNy---oN+yd..../ymhyssyhyo-...:M:------
--------------------/N/.....................:dh/---:hd+-...-oms--/hd/sm:../dy/-......:sd/..sNy:-----
---------------------sm:......................ohh+:--+yhyyyhy+/ohh+/hh:..+m/...y:....../Nshs:om/----
----------------------omo......................./shyysoossyyyhyo::sdo-...No....ods/---:oN/-...my----
----------------.------:hd+-.......................-:/++++//:--/hdo-....:M:.....-+smhymd:...-oN+----
.......................:hdyhs/-...........................-:+yhyym:.....-Ns.....-/yd-.:yhsoydh/-----
......................-dh--:+yhyo+:--..............---/+syhyo/---my...--+mmo....ss/.....-/dm/-------
......................-M+------:+oyhhhyyysssssyyyhhhyys+/:------:No----ym/:yd+-.........:hh:--------
......................:md:-------------:://///::--------------:smy--:sms----:sdy+:-.-:ohd+----------
....................:hdoodds+:-----------------------------/sddshmhdho---------:osydMyo:------------
...................sm+-----/sy:-------------------------+ydho:::+mN/--------------+No---------------
..................yd:-------------------------------/shdy+:::/ydh++N+------------sm+----------------
.................yd:----------------------------:+ydho/:::/sdho:---+N/---------/dh/-----------------
................sm:--------------------------/shhy+/:::/sdho:-------ym-------:sdo:----------------::
.............../N/-----------------------:+yhyo/:::::::+Ny----------:N+----:sds:----------:---:::-::
..............-ms--------------------:+shhs+/:::::+ss/::+my----------hd-:+yhs/-------:::::::::::::::
..............yd-----------s:----:/shhyo/:::::/+yhhmmdo::+N+---------/Mhhy+:---:::::::::::::::::::::
.............+N:----------oN::+shhyo/::::::/oyhyo/:dy-dy::ym----------Ny::::::::::::::::::::::::::::
............-No-----------mmhhyo/::::::/+shhy+:::::sm:yd::sN----------hh::::::::::::::::::::::::::::
............hh-----------+M+::::::::/oydho/:::::::::oso/::dh----------sm::::::::::::::::::::::::::::
```````````+N:-----------mh:::::/+yhdy+::::::::::::::::::sN:----------oN::::::::::::::::::::::::::::
``````````-No-----------+M/::::odyo/:::::::::::::::::::/hd:-----------oM::::::::::::::::::::::::::::
``````````hh------------dh::::::::::::::::::::::::::/sddo-------------+M::::::::::::::::::::::::::::
*/

contract PhantaDoodles is OptimizedERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public price = 0.025 ether;
    uint256 public maxPerTransaction = 20;
    uint256 public maxPerWallet = 100;
    uint256 public maxTotalSupply = 5000;
    uint256 public freeMintCount = 500;

    bool public saleAllowed = false;

    string public baseURI;

    address private withdrawAddress = address(0);

    mapping(address => uint256) public mintsPerWallet;

    constructor(string memory name, string memory symbol, address _withdrawAddress) OptimizedERC721Enumerable(name, symbol) {
        withdrawAddress = _withdrawAddress;
    }

    function privateMint(uint256 _amount, address _receiver) external onlyOwner {
        require(_amount > 0, "Must mint at least one");
        require(totalSupply().add(_amount) <= maxTotalSupply, "Exceeds max supply");

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_receiver);
        }
    }

    function mint(uint256 _amount) external payable nonReentrant {
        require(saleAllowed, "Sale not allowed");
        require(_amount > 0, "Must mint at least one");
        require(_amount <= maxPerTransaction, "Exceeds max allowed per transaction");
        require(totalSupply().add(_amount) <= maxTotalSupply, "Exceeds max supply");
        require(price.mul(_amount) <= msg.value, "Ether value sent is not correct");

        uint256 walletCount = mintsPerWallet[_msgSender()];
        require(_amount.add(walletCount) <= maxPerWallet, "Exceeds max allowed per wallet");

        for (uint256 i = 0; i < _amount; i++) {
            mintsPerWallet[_msgSender()] = mintsPerWallet[_msgSender()].add(1);
            _safeMint(_msgSender());
        }
    }

    function freeMint(uint256 _amount) external nonReentrant {
        require(saleAllowed, "Sale not allowed");
        require(_amount > 0, "Must mint at least one");
        require(_amount <= maxPerTransaction, "Exceeds max allowed per transaction");
        require(totalSupply().add(_amount) <= maxTotalSupply, "Exceeds max supply");
        require(totalSupply().add(_amount) <= freeMintCount, "Exceeds free mint count");

        uint256 walletCount = mintsPerWallet[_msgSender()];
        require(_amount.add(walletCount) <= maxPerWallet, "Exceeds max allowed per wallet");

        for (uint256 i = 0; i < _amount; i++) {
            mintsPerWallet[_msgSender()] = mintsPerWallet[_msgSender()].add(1);
            _safeMint(_msgSender());
        }
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Token not owned or approved");
        _burn(tokenId);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMaxTotalSupply(uint256 _maxValue) external onlyOwner {
        maxTotalSupply = _maxValue;
    }

    function setMaxPerTransaction(uint256 _maxValue) external onlyOwner {
        maxPerTransaction = _maxValue;
    }

    function setMaxPerWallet(uint256 _maxValue) external onlyOwner {
        maxPerWallet = _maxValue;
    }

    function setFreeMintCount(uint256 _count) external onlyOwner {
        freeMintCount = _count;
    }

    function setSaleAllowed(bool _allowed) external onlyOwner {
        saleAllowed = _allowed;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        require(withdrawAddress != address(0), "Withdraw address not set");

        uint256 contractBalance = address(this).balance;
        payable(withdrawAddress).transfer(contractBalance);
    }

    function setWithdrawAddress(address _newWithdrawAddress) external onlyOwner {
        withdrawAddress = _newWithdrawAddress;
    }
}
