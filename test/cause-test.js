const { expect } = require("chai");

describe("Cause contract", function () {

  let Contract;
  let FeeManager;
  let fm_contract;
  let FactoryContract;
  let hardhatToken;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addr4;
  let addr5;
  let addr6;
  let addr7;
  let addrs;

  beforeEach(async function () {
    Contract = await ethers.getContractFactory("Cause");
    FeeManagerContract = await ethers.getContractFactory("FeeManagerERC20");
    fm_contract = await FeeManagerContract.deploy();
    [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, ...addrs] = await ethers.getSigners();
  });

  async function create_basic_contract() {
    c_contract = await Contract.deploy(owner.address, fm_contract.address, "", 1000000, 1);
    return c_contract;
  }

  describe("Voting tests. ", function () {

    it("Test simple approve case. ", async function () {
      var cc00 = await fm_contract.connect(owner).transfer(addr2.address, 2400000_000_000_000);

      c_contract = await create_basic_contract()
      var cc01 = await c_contract.connect(addr2).approve({ value: 100000000000000 });
      var cc02 = await c_contract.approve_count();
      expect(cc02).to.equal(1);

      var cc03 = await fm_contract.connect(addr2).withdraw();
      var receipt = await cc03.wait();
      expect(receipt.events.filter((x) => {return x.event == "Withdrawn"})[0].args.amount.toNumber()).to.equal(99999984000000);
    });

    it("Test complex approve case. ", async function () {
      var cc00 = await fm_contract.connect(owner).transfer(addr2.address, 2400000_000_000_000);

      c_contract = await create_basic_contract()
      var cc01 = await c_contract.connect(addr2).approve({ value: 100000000000000 });
      var cc02 = await c_contract.approve_count();
      expect(cc02).to.equal(1);

      var cc03 = await c_contract.connect(addr3).approve({ value: 100000000000000 });
      var cc04 = await c_contract.approve_count();
      expect(cc04).to.equal(2);

      await expect(c_contract.connect(addr3).approve({ value: 100 })).to.be.revertedWith("Not enough money sent. ");
      await expect(c_contract.connect(addr3).approve({ value: 100000000000000 })).to.be.revertedWith("Already approved. ");

      var cc05 = await fm_contract.connect(addr2).withdraw();
      var receipt = await cc05.wait();
      expect(receipt.events.filter((x) => {return x.event == "Withdrawn"})[0].args.amount.toNumber()).to.equal(199999992000000);
    });
  });
});
