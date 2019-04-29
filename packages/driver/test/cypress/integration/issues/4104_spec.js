const _ = Cypress._

describe('lots of assertions run against an HTML page with a large external stylesheet', () => {
  beforeEach(() => {
    cy.visit('/fixtures/issue-4104.html')
  })
  _.range(1, 51).forEach((n) => {
    it(`assertion ${n}`, () => {
      cy.get('#test').should('be.visible')
    })
  })
})
