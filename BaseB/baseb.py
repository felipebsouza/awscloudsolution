
from sqlalchemy import * 

from sqlalchemy import create_engine  
from sqlalchemy import Column, String, MetaData,Integer
from sqlalchemy.ext.declarative import declarative_base  
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import DeclarativeMeta
import json

# change to import from enviroment
db_string = "mysql+cymysql://sa:baseBpassword@baseb.cxtedbgsblnr.sa-east-1.rds.amazonaws.com/baseb"

engine = create_engine(db_string, echo=True)  
base = declarative_base()

metadata = MetaData(engine)

personaldatatable = Table('PersonalData', metadata,
    Column('cpf', String(18), primary_key=True),
    Column('age', Integer),
    Column('address', String(50)),
    Column('addressvalue', Integer),
    Column('salary', Integer)
    )

wealthtable = Table('Wealth', metadata,
    Column('id', Integer, primary_key=True),
    Column('cpf', String(18)),
    Column('gooddescription', String(30)),
    Column('goodvalue', Integer)
    )


class PersonalData(base):
    __tablename__ = 'PersonalData'
    cpf = Column(String(18), primary_key=True)
    age = Column(Integer)
    address = Column(String(50))
    addressvalue = Column(Integer)
    salary = Column(Integer)

    def as_dict(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Wealth(base):
    __tablename__ = 'Wealth'
    id = Column(Integer, primary_key=True)
    cpf = Column(String(18))
    gooddescription = Column(String(30))
    goodvalue = Column(Integer)

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
        # getScoreProfile: return personal data for calculate score values
        # argument input: cpf ->  output: cpf, age, adddress, addressvalue, salary, list of goods
        if (event["action"] == "getScoreProfile"):
            personaldata = session.query(PersonalData).filter(PersonalData.cpf == event["cpf"]).first()
            wealthquery = session.query(Wealth).filter(Wealth.cpf == event["cpf"])

            wealthprofile = {}
            wealthprofile.update(personaldata.as_dict())
            goods = []
            for _row in wealthquery.all():
                goods.append({_row.gooddescription: _row.goodvalue})
                
            wealthprofile.update({'Goods:':goods})

            response = wealthprofile
        
        elif(event["action"] == "addPersonalData"):
            data = PersonalData(cpf = event["cpf"], age = event["age"], address = event["address"], addressvalue=event["addressvalue"], salary=event["salary"])
            session.add(data)
            session.commit()
            response = data.as_dict()
        elif(event["action"] == "addGood"):
            newgood = Wealth(cpf = event["cpf"], gooddescription = event["gooddescription"], goodvalue = event["goodvalue"])
            session.add(newgood)
            session.commit()
            response = newgood.as_dict()
        print("ok")

        return response

        
    except Exception, e:
        session.rollback()
        return str(e)

