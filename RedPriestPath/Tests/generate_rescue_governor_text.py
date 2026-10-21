"""Generate the isolated bilingual rescue governor overlay; no shared-pack rows."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]

def main():
    tags=None
    for language in ('zh_Hans_CN','en_US'):
        source=ROOT/'Text'/language/'LOTM_RESCUE_Governors.xml'
        rows=list(ET.parse(source).getroot().find('./LocalizedText'))
        keys={(row.tag,row.get('Tag')) for row in rows}
        assert len(rows)==7 and len(keys)==7
        assert sum(row.tag=='Replace' for row in rows)==1
        assert ('Replace','LOC_LOTM_MS_INVESTIGATION_DESC') in keys
        assert all(row.get('Language')==language for row in rows)
        if tags is not None:assert tags==keys
        tags=keys
        out=ROOT/'Text/Selected'/f'LOTM_RESCUE_Governors_{language}.xml'
        root=ET.Element('GameData');base=ET.SubElement(root,'BaseGameText')
        base.append(ET.Comment(f' Generated from Text/{language}/LOTM_RESCUE_Governors.xml; rescue-only overlay. '))
        for row in rows:
            outrow=ET.SubElement(base,'Replace',Tag=row.get('Tag'))
            ET.SubElement(outrow,'Text').text=row.findtext('Text')
        ET.indent(root,space='\t')
        out.write_bytes(ET.tostring(root,encoding='utf-8',xml_declaration=True)+b'\n')
        print(f'Generated {out.name}: 6 new tags, 1 rescue B2 override')

if __name__=='__main__':main()
