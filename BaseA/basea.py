
from sqlalchemy import * 

from sqlalchemy import create_engine  
from sqlalchemy import Column, String, MetaData,Integer
from sqlalchemy.ext.declarative import declarative_base  
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import DeclarativeMeta
import json

db_string = "mysql+cymysql://sa:baseApassword@basea.cxtedbgsblnr.sa-east-1.rds.amazonaws.com/basea"

engine = create_engine(db_string, echo=True)  
base = declarative_base()

metadata = MetaData(engine)

persontable = Table('Person', metadata,
    Column('cpf', String(18), primary_key=True),
    Column('name', String(50)),
    Column('address', String(50))
    )

debtstable = Table('Debts', metadata,
    Column('id', Integer, primary_key=True),
    Column('cpf', String(18)),
    Column('debt', String(30))
    )


class Person(base):
    __tablename__ = 'Person'
    cpf = Column(String(18), primary_key=True)
    name = Column(String(50))
    address = Column(String(50))
    def as_dict(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Debts(base):
    __tablename__ = 'Debts'
    id = Column(Integer, primary_key=True)
    cpf = Column(String(18))
    debt = Column(String(30))
    def as_dict(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

def merge_two_dicts(x, y):
    z = x.copy()  
    z.update(y)    
    return z
    
def lambda_handler(event, context):
   
    try:
        Session = sessionmaker(bind=engine)
        session = Session()
        metadata.create_all()
        if (event["action"] == "getData"):
            person = session.query(Person).filter(Person.cpf == event["cpf"]).first()
            debtsquery = session.query(Debts).filter(Debts.cpf == event["cpf"])

            profile = {}
            profile.update(person.as_dict())
            debts = []
            for _row in debtsquery.all():
                debts.append({_row.id: _row.debt})
                
            profile.update({'Debts:':debts})

            response = profile
        
        elif(event["action"] == "addPerson"):
            person = Person(cpf = event["cpf"], name = ["name"], address = ["address"])
            session.add(person)
            session.commit()
            response = person.as_dict()
        elif(event["action"] == "addDebt"):
            debts = Debts(cpf = event["cpf"], debt = event["debt"])
            session.add(debts)
            session.commit()
            response = debts.as_dict()
        print("ok")

        return response
        
    except Exception, e:
        session.rollback()
        return str(e)

