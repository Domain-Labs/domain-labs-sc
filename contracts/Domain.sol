// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Domain is Ownable {
    struct DOMAIN {
        address owner;
        uint256 buyDate;
        string name;
        uint256 durationTime;
    }
    struct SUBDOMAIN {
        string SUBDOMAIN;
        string STR;
    }

    mapping(string => address) private customer;
    mapping(string => DOMAIN) private domainByName;
    mapping(string => mapping(string => string)) private domainS;
    mapping(address => DOMAIN[]) private domainsByOwner;
    mapping(string => SUBDOMAIN[]) private subdomainsByDomain;
    uint256 private devFeeVal = 15;
    string[] public row;
    uint256 public pricePerDay = 10;
    uint256 private MINUTE_IN_DAY = 24 * 60 * 60;
    address payable private recAdd;

    constructor() {
        recAdd = payable(msg.sender);
    }

    function isDomain(string memory name) public view returns (bool) {
        if (customer[name] == address(0)) {
            return false;
        } else if (
            block.timestamp - domainByName[name].buyDate >
            domainByName[name].durationTime
        ) {
            return false;
        }
        return true;
    }

    function setPricePerDay(uint256 value) public onlyOwner {
        pricePerDay = value;
    }

    function devFee(uint256 amount) private view returns (uint256) {
        return (amount * devFeeVal) / 100;
    }

    function bulkIsdomain(string[] memory names)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory result = new bool[](names.length);
        for (uint i = 0; i < names.length; i++) {
            result[i] = isDomain(names[i]);
        }
        return result;
    }

    function buyDomain(string memory dname, uint256 durationTime)
        public
        payable
    {
        if (
            block.timestamp - domainByName[dname].buyDate >
            domainByName[dname].durationTime
        ) {
            customer[dname] = address(0);
        }
        require(!isDomain(dname), "It is already on the list!");
        uint256 price = calculatePrice(durationTime);
        price = price - devFee(price);
        uint256 fee = devFee(price);
        recAdd.transfer(fee);
        customer[dname] = msg.sender;
        DOMAIN memory domain;
        domain.buyDate = block.timestamp;
        domain.name = dname;
        domain.owner = msg.sender;
        domain.durationTime = durationTime;
        domainByName[dname] = domain;
        domainsByOwner[msg.sender].push(domain);
    }

    function calculatePrice(uint256 duration) private view returns (uint256) {
        return (pricePerDay * duration) / MINUTE_IN_DAY;
    }

    function bulkBuyDomain(
        string[] memory dnames,
        uint256[] memory durationTimes
    ) public payable {
        uint256 len = dnames.length;
        uint256 totalPrice = 0;
        require(len == durationTimes.length, "need to same length");

        for (uint256 i = 0; i < len; i++) {
            totalPrice += pricePerDay * durationTimes[i];
        }

        require(totalPrice <= msg.value, "not enough price");

        for (uint256 i = 0; i < len; i++) {
            buyDomain(dnames[i], durationTimes[i]);
        }
    }

    function registerS(
        string memory subDname,
        string memory dname,
        string memory str
    ) public {
        require(customer[dname] == msg.sender, "You are not the owner!");
        domainS[dname][subDname] = str;
        SUBDOMAIN memory dom = SUBDOMAIN(subDname, str);
        subdomainsByDomain[dname].push(dom);
    }

    function readDomains() public view returns (DOMAIN[] memory) {
        return domainsByOwner[msg.sender];
    }

    function readDomainByName(string memory name)
        public
        view
        returns (DOMAIN memory)
    {
        return domainByName[name];
    }

    function reawdSubdomains(string memory dname)
        public
        view
        returns (SUBDOMAIN[] memory)
    {
        return subdomainsByDomain[dname];
    }
}
